class StatsController < ApplicationController
  def index
    @positions = Hash.new { |hash, key| hash[key] = Array.new }
    Player.all.includes(:season_totals).each do |player|
      @positions[player.position] << player
    end
    @positions.each do |label, array|
      array.sort! do |x, y| 
        xcomp = x.season_totals[0].nil? ? 0 : x.season_totals[0].total_points 
        ycomp = y.season_totals[0].nil? ? 0 : y.season_totals[0].total_points
        ycomp <=> xcomp
      end
    end
  end

  def player
    @player = Player.find(params[:id])   
  end


  #JSON Endpoints for graph data
  def player_points_by_game
    player = Player.find(params[:id])
    stats = Statline.where player: player
    data = Array.new
    labels = Array.new
    stats.each do |line|
      labels << line.opponent.name 
      data << line.points
    end
    json = { data: data, labels: labels }

    render json: json
  end
  
end
