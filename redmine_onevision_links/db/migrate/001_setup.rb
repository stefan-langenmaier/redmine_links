class Setup < ActiveRecord::Migration

  def self.up
    create_table "links", :force => true do |t|
      t.column "container_id", :integer, :default => 0, :null => false
      t.column "container_type", :string, :limit => 30, :default => "", :null => false
      t.column "filename", :string, :default => "", :null => false
      t.column "fileaddress", :string, :default => "", :null => false
      t.column "filesize", :integer, :default => 0, :null => false
      t.column "content_type", :string, :limit => 60, :default => ""
      t.column "digest", :string, :limit => 40, :default => "", :null => false
      t.column "downloads", :integer, :default => 0, :null => false
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "created_on", :timestamp
      t.column "description", :string
    end
  end
  
  def self.down
    drop_table "attachments"
  end
end