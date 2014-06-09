class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name
      t.string :position
      t.integer :riot_id, index: true

      t.timestamps
    end

    add_reference :players, :team, references: :players
  end
end
