# == Schema Information
#
# Table name: season_totals
#
#  id                :integer          not null, primary key
#  player_id         :integer
#  total_kills       :integer
#  total_deaths      :integer
#  total_assists     :integer
#  total_cs          :integer
#  total_triple_kill :integer
#  total_quadra_kill :integer
#  total_penta_kill  :integer
#  total_ten_ka      :integer
#  total_win         :integer
#  total_baron       :integer
#  total_dragon      :integer
#  total_first_blood :integer
#  total_tower       :integer
#  total_time        :integer
#  total_points      :float
#  created_at        :datetime
#  updated_at        :datetime
#

class SeasonTotal < ActiveRecord::Base
  belongs_to :player
end
