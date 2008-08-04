class CreateBudas < ActiveRecord::Migration
  def self.up
    create_table :budas do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :budas
  end
end
