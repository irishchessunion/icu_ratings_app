class AddRerateToTournament < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :rerate, :boolean, default: false
  end
end
