class InitialSphinxSetup < ActiveRecord::Migration
  def self.up
    create_table :sphinx_counter, :force => true do |t|
      t.integer :max_doc_id
    end
  end

  def self.down
    drop_table :sphinx_counter
  end
end

