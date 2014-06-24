require 'open-uri'

BASE_URL = "http://na.lolesports.com/api"
def open_api_as_array(endpoint)
  f = open(BASE_URL + endpoint)
  data = JSON.parse(f.read)
  f.close()
  data
end

def no_nulls(data)
  if data.blank?
    0
  else
    data
  end
end

def variance(data, mean)
  return 0 if data.count == 0
  total_deviation = 0.0
  data.each do |datum|
    total_deviation += (datum - mean).abs 
  end
  total_deviation / data.count  
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
        player = Player.find_by riot_id: no_nulls(team_stats["teamId"])
        line = Statline.find_or_initialize_by(player: player, game: game)
        line.date = date
        line.match = match
        line.win = no_nulls(team_stats["matchVictory"])
        line.baron = no_nulls(team_stats["baronsKilled"])
        line.dragon = no_nulls(team_stats["dragonsKilled"])
        line.first_blood = no_nulls(team_stats["firstBlood"])
        line.tower = no_nulls(team_stats["towersKilled"])
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
        player = Player.find_by riot_id: no_nulls(player_stats["playerId"]) 
        line = Statline.find_or_initialize_by(player: player, game: game)
        line.date = date
        line.match = match
        line.kills = no_nulls(player_stats["kills"])
        line.deaths = no_nulls(player_stats["deaths"])
        line.assists = no_nulls(player_stats["assists"])
        line.ten_ka = (line.kills >= 10 or line.assists >= 10) ? 1 : 0
        line.cs = no_nulls(player_stats["minionKills"])
        line.double_kill = no_nulls(player_stats["doubleKills"])
        line.triple_kill = no_nulls(player_stats["tripleKills"])
        line.quadra_kill = no_nulls(player_stats["quadraKills"])
        line.penta_kill = no_nulls(player_stats["pentaKills"])
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
      totals.ppg = totals.total_points / player_stats.count
      totals.variance = variance(player_stats.pluck(:points), totals.ppg) #average abs deviation
      totals.save
    end
  end

  desc "Identify starters/replacement level"
  task :starters, [:teams] => :environment do |t, args|
    players = Player.all.includes(:season_totals).to_a
    teams = (0 .. (args.teams.to_i - 1)).to_a
    players.sort! do |x, y|
      xcomp = x.season_totals[0].nil? ? 0 : x.season_totals[0].total_points 
      ycomp = y.season_totals[0].nil? ? 0 : y.season_totals[0].total_points
      ycomp <=> xcomp
    end

    #pobelter still in here
    positions = Hash.new { |hash, key| hash[key] = Array.new }
    starters = positions.clone
    backups = positions.clone
    players.delete_if do |player|
      if positions[player.position].count < 12
        positions[player.position] << player
        false
      else
        true #delete in place
      end
    end

    #positional starters
    positions.each do |label, array|
      teams.each do |idx|
        starters[label] << players.delete(array.delete_at(0))
      end
    end

    #flex starters
    teams.each do |idx|
      player = players.delete_at(0)
      starters[player.position] << positions[player.position].delete(player)
    end

    #flex backups
    (teams * 3).each do |idx| 
      player = players.delete_at(0)
      backups[player.position] << positions[player.position].delete(player)
    end 

    positions.each do |label, array|
      puts "--" + label + "--"
      puts "Starters:"
      starters[label].each do |starter|
        puts starter.name + "\t" + starter.season_totals[0].ppg.to_s(:rounded, precision: 2)
      end
      puts "Backups:"
      backups[label].each do |backup|
        puts backup.name + "\t" + backup.season_totals[0].ppg.to_s(:rounded, precision: 2)
      end
    end
  end
  
  desc "Create seed file from db contents"
  task :build_seed => :environment do |t, args|
    #TODO
  end

end
