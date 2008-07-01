class CreateBrecords < ActiveRecord::Migration
  def self.up
    create_table :brecords do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :brecords
  end
end
