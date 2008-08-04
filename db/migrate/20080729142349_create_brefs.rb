class CreateBrefs < ActiveRecord::Migration
  def self.up
    create_table :brefs do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :brefs
  end
end
