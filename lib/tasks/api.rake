require 'open-uri'
require 'ai4r'
include Ai4r::Data
include Ai4r::Clusterers

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
        #update the team      
        team = Player.find_or_initialize_by(riot_id: no_nulls(team_stats["teamId"]))
        team.update(name: team_stats['teamName'], position: 'Team')
        team.save

        #update the stats
        line = Statline.find_or_initialize_by(player: team, game: game)
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
        #update the player
        player = Player.find_or_initialize_by(riot_id: no_nulls(player_stats["playerId"]))
        player.update(name: player_stats['playerName'], position: player_stats['role'])
        player.save
        
        #update the player stats
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
        unless line.player.team.nil?
          line.opponent = opponents[line.player.team.riot_id]
        end
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

  desc "Update player tiers"
  task :tier => :environment do |t, args|
    # for each position
    position_hash = Hash.new{|h, k| h[k] = []}
    Player.all.collect { |p| position_hash[p.position] << p }

    position_hash.each do |pos, members|
      # make a data set out of the members

      #the label and the get_player_data functions need to be kept in sync
      #if you want to consider another value in the data, add a corresponding label
      #throw all the data we have at it
      labels = ['total_kills', 'total_deaths', 'total_assits', 'total_cs', 'total_ten_ka', 'total_win', 'total_baron', 'total_dragon', 'total_first_blood', 'total_tower', 'total_time', 'total_points']
      def get_player_data (p)
        player_totals = SeasonTotal.find_by player:p
        [player_totals.total_kills, player_totals.total_deaths, player_totals.total_assists, player_totals.total_cs, player_totals.total_ten_ka, player_totals.total_win, player_totals.total_baron, player_totals.total_dragon, player_totals.total_first_blood, player_totals.total_tower, player_totals.total_time, player_totals.total_points]
      end

      data = members.map { |p| get_player_data(p) }

      # cluster them into tiers
      data_set = DataSet.new(:data_items => data, :data_labels => labels)
      # http://en.wikipedia.org/wiki/Determining_the_number_of_clusters_in_a_data_set
      # went with rule of thumb for now
      #num_clusters = Math.sqrt(data.length / 2).floor
      num_clusters = 8 #the number of clusters Carl set before
      clusterer = Diana.new.build(data_set, num_clusters)

      # order the tiers, so we know which is best
      def get_cluster_avg_points(c)
        total_points_index = c.get_index('total_points')
        c.get_mean_or_mode[total_points_index]
      end

      clusterer.clusters.sort! {|x,y| get_cluster_avg_points(y) <=> get_cluster_avg_points(x)}

      # record the results
      members.each do |p|
        player_data = get_player_data p
        #clusters are 0 based, we want tiers to be 1 based
        tier = clusterer.eval(player_data) + 1
        p.update(tier: tier)
        p.save
      end
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
