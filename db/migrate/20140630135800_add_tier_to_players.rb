class AddTierToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :tier, :integer
  end
end
