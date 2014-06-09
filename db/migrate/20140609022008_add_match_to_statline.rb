class AddMatchToStatline < ActiveRecord::Migration
  def change
    add_column :statlines, :match, :integer
  end
end
