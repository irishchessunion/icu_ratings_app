class AddFideIdToTournament < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :fide_id, :integer
  end
end
