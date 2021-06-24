class AddFullRatingBoolean < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :old_full, :boolean, default: false
    add_column :players, :new_full, :boolean, default: false
  end
end
