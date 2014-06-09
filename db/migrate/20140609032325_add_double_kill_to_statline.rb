class AddDoubleKillToStatline < ActiveRecord::Migration
  def change
    add_column :statlines, :double_kill, :integer
  end
end
