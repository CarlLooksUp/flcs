# == Schema Information
#
# Table name: players
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  position   :string(255)
#  riot_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  team_id    :integer
#

class Player < ActiveRecord::Base
  belongs_to :team, class_name: :Player
  has_many :season_totals
  has_many :statlines
end
