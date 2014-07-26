class CreatePlayerComments < ActiveRecord::Migration
  def change
    create_table :player_comments do |t|
      t.integer :player_id
      t.text :comment
      t.integer :author_id

      t.timestamps
    end
  end
end
