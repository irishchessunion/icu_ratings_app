class AddIterationsToTournament < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :iterations1, :integer, limit: 2, default: 0
    add_column :tournaments, :iterations2, :integer, limit: 2, default: 0
  end
end
