class ResizeDescription < ActiveRecord::Migration

  def self.up
    change_table "links" do |t|
      t.change(:description, :text)
    end
  end
  
  def self.down
    change_table "links" do |t|
      t.change(:description, :string)
    end
  end
end