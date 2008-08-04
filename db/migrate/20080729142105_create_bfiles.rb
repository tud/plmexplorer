class CreateBfiles < ActiveRecord::Migration
  def self.up
    create_table :bfiles do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :bfiles
  end
end
