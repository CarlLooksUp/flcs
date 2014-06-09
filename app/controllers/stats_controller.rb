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
end
