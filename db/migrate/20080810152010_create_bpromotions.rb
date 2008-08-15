class CreateBpromotions < ActiveRecord::Migration
  def self.up
    create_table :bpromotions do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :bpromotions
  end
end
