class CreateBchkhistories < ActiveRecord::Migration
  def self.up
    create_table :bchkhistories do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :bchkhistories
  end
end
