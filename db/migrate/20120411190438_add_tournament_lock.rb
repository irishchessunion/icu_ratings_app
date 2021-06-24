class AddTournamentLock < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :locked, :boolean, default: false
  end
end
