class AddPreferences < ActiveRecord::Migration
  def change
    add_column :spree_recurrings, :preferences, :text
  end
end
