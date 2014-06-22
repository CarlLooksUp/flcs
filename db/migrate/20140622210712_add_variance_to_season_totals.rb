class AddVarianceToSeasonTotals < ActiveRecord::Migration
  def change
    add_column :season_totals, :variance, :integer
  end
end
