class ChangeVarianceToFloat < ActiveRecord::Migration
  def change
    change_column :season_totals, :variance, :float
  end
end
