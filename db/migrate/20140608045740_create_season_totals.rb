class CreateSeasonTotals < ActiveRecord::Migration
  def change
    create_table :season_totals do |t|
      t.references :player
      t.integer :total_kills
      t.integer :total_deaths
      t.integer :total_assists
      t.integer :total_cs
      t.integer :total_triple_kill
      t.integer :total_quadra_kill
      t.integer :total_penta_kill
      t.integer :total_ten_ka
      t.integer :total_win
      t.integer :total_baron
      t.integer :total_dragon
      t.integer :total_first_blood
      t.integer :total_tower
      t.integer :total_time
      t.float :total_points

      t.timestamps
    end
  end
end
