require 'open-uri'

BASE_URL = "http://na.lolesports.com/api"
def open_api_as_array(endpoint)
  f = open(BASE_URL + endpoint)
  data = ActiveSupport::JSON.decode(f.read)
  f.close()
  data
end

namespace :api do
  desc "Pull in all players for a season"
  task :players, [:season_id] => :environment do |t, args|
    #start with teams
    teams = open_api_as_array("/tournament/#{args.season_id}.json")['contestants']
    teams.each do |label, info|
      t = Player.find_or_initialize_by(riot_id: info['id'])
      t.update(name: info['name'], position: 'Team')
      t.save

      #for each team pull roster
      players = open_api_as_array("/team/#{t.riot_id}.json")['roster']
      players.each do |plabel, pinfo|
        p = Player.find_or_initialize_by(riot_id: pinfo['playerId'])
        p.update(name: pinfo['name'], position: pinfo['role'], team: t)
        p.save
      end
    end
  end

  desc "Pull in all available stat lines"
  task :stats, [:season_id] => :environment do |t, args|
    #open up the season stat json
    stat_library = open_api_as_array("/gameStatsFantasy.json?tournamentId=#{args.season_id}")
    
    #Compile all team statlines
    stat_library['teamStats'].each do |gameId, stats|
      game = gameId.split("game")[1]
      date = stats.delete("dateTime")
      match = stats.delete("matchId")
      lines = []
      stats.each do |teamId, team_stats|
        player = Player.find_by riot_id: team_stats["teamId"] 
        line = Statline.find_or_initialize_by(player: player, game: game)
        line.date = date
        line.match = match
        line.win = team_stats["matchVictory"]
        line.baron = team_stats["baronsKilled"]
        line.dragon = team_stats["dragonsKilled"]
        line.first_blood = team_stats["firstBlood"]
        line.tower = team_stats["towersKilled"]
        line.points = line.calc_points
        lines << line
      end
      lines[0].opponent = lines[1].player
      lines[1].opponent = lines[0].player
      lines[0].save
      lines[1].save
    end

    #Compile all player statlines
    stat_library['playerStats'].each do |gameId, stats|
      game = gameId.split("game")[1]
      date = stats.delete("dateTime")
      match = stats.delete("matchId")
      teams_lines = Statline.where(game: game)
      opponents = Hash.new
      teams_lines.each do |t|
        opponents[t.player.riot_id] = t.opponent
      end
      stats.each do |playerId, player_stats|
        player = Player.find_by riot_id: player_stats["playerId"] 
        line = Statline.find_or_initialize_by(player: player, game: game)
        line.date = date
        line.match = match
        line.kills = player_stats["kills"]
        line.deaths = player_stats["deaths"]
        line.assists = player_stats["assists"]
        line.ten_ka = line.kills + line.assists >= 10 ? 1 : 0
        line.cs = player_stats["minionKills"]
        line.double_kill = player_stats["doubleKills"]
        line.triple_kill = player_stats["tripleKills"]
        line.quadra_kill = player_stats["quadraKills"]
        line.penta_kill = player_stats["pentaKills"]
        line.points = line.calc_points
        line.opponent = opponents[line.player.team.riot_id]
        line.save
      end
    end
  end

  desc "Update season totals"
  task :totals => :environment do |t, args|
    Player.all.each do |player|
      totals = SeasonTotal.find_or_initialize_by(player: player)
      player_stats = Statline.where(player: player)
      #player
      totals.total_kills = player_stats.sum(:kills) 
      totals.total_deaths = player_stats.sum(:deaths)
      totals.total_assists = player_stats.sum(:assists)
      totals.total_cs = player_stats.sum(:cs)
      totals.total_triple_kill = player_stats.sum(:triple_kill)
      totals.total_quadra_kill = player_stats.sum(:quadra_kill)
      totals.total_penta_kill = player_stats.sum(:penta_kill)
      totals.total_ten_ka = player_stats.sum(:ten_ka)

      #team
      totals.total_win = player_stats.sum(:win)
      totals.total_baron = player_stats.sum(:baron)
      totals.total_dragon = player_stats.sum(:dragon)
      totals.total_first_blood = player_stats.sum(:first_blood)
      totals.total_tower = player_stats.sum(:tower)

      totals.total_time = player_stats.sum(:time)
      totals.total_points = player_stats.sum(:points)
    end
  end

  desc "Create seed file from db contents"
  task :build_seed => :environment do |t, args|
    #TODO
  end

end
