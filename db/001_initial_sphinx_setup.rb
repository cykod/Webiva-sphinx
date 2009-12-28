class InitialSphinxSetup < ActiveRecord::Migration
  def self.up
    create_table :sphinx_counters, :force => true do |t|
      t.datetime :max_updated_at
    end
  end

  def self.down
    drop_table :sphinx_counters
  end
end

