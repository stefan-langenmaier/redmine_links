class ResizeFileaddress < ActiveRecord::Migration

  def self.up
    change_table "links" do |t|
      t.change(:fileaddress, :string, :limit => 1024)
    end
  end
  
  def self.down
    change_table "links" do |t|
      t.change(:fileaddress, :string, :limit => 255)
    end
  end
end