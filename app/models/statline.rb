# == Schema Information
#
# Table name: statlines
#
#  id          :integer          not null, primary key
#  player_id   :integer
#  season      :string(255)
#  date        :datetime
#  week        :integer
#  game        :integer
#  match       :integer
#  kills       :integer
#  deaths      :integer
#  assists     :integer
#  cs          :integer
#  double_kill :integer
#  triple_kill :integer
#  quadra_kill :integer
#  penta_kill  :integer
#  ten_ka      :integer
#  win         :integer
#  baron       :integer
#  dragon      :integer
#  first_blood :integer
#  tower       :integer
#  time        :integer
#  points      :float
#  created_at  :datetime
#  updated_at  :datetime
#  opponent_id :integer
#

class Statline < ActiveRecord::Base
  belongs_to :player
  belongs_to :opponent, class_name: :Player #always a team

  def calc_points
    if self.player.position == "Team"
      self.win * 2 + self.baron * 2 + self.dragon * 1 + self.first_blood * 2 + self.tower * 1
    else
      self.kills * 2 + self.deaths * (-0.5) + self.assists * (1.5) + self.cs * 0.01 + self.triple_kill * 2 + self.quadra_kill * 5 + self.penta_kill * 10 + self.ten_ka * 2
    end
  end
end
