class AddNoteToTournament < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :notes, :text
  end
end
