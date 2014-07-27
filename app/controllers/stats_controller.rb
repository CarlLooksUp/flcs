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
    @recent_comment = @player.player_comments.order(created_at: :asc).last
  end

  def compare
    @players = Player.all
    @weeks = (1..total_weeks).to_a
  end


  #JSON Endpoints for graph data
  def player_points_by_game
    player = Player.find(params[:id])
    stats = Statline.where(player: player).order(date: :asc)
    data = Array.new
    labels = Array.new
    stats.each do |line|
      labels << line.opponent.name
      data << line.points
    end
    json = { name: player.name, data: data, labels: labels }

    render json: json
  end

  def player_points_by_week
    player = Player.find(params[:id])
    stats = Statline.where(player: player).order(date: :asc)
    data = Array.new(total_weeks, 0)
    stats.each do |line|
      data[week(line.date)] += line.points
    end

    json = { name: player.name, data: data }
    render json: json
  end

  private
    def total_weeks
      week(DateTime.now)
    end

    def first_day
      first_day = Rails.cache.fetch('first_day') {
        Statline.order(date: :asc).first.date
      }
    end

    #zero indexed
    def week(date)
      (date.to_date - first_day.to_date).to_i / 7
    end
end
