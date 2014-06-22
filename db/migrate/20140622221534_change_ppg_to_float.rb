class ChangePpgToFloat < ActiveRecord::Migration
  def change
    change_column :season_totals, :ppg, :float
  end
end
