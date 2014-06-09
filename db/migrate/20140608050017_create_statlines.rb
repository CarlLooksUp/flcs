class CreateStatlines < ActiveRecord::Migration
  def change
    create_table :statlines do |t|
      t.references :player
      t.string :season
      t.datetime :date
      t.integer :week
      t.integer :game
      t.integer :kills
      t.integer :deaths
      t.integer :assists
      t.integer :cs
      t.integer :triple_kill
      t.integer :quadra_kill
      t.integer :penta_kill
      t.integer :ten_ka
      t.integer :win
      t.integer :baron
      t.integer :dragon
      t.integer :first_blood
      t.integer :tower
      t.integer :time
      t.float :points

      t.timestamps
    end

    add_reference :statlines, :opponent, references: :players
  end
end
