class AddUnrateablePlayer < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :unrateable, :boolean, default: false
  end
end
