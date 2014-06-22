class AddPpgToSeasonTotals < ActiveRecord::Migration
  def change
    add_column :season_totals, :ppg, :integer
  end
end
