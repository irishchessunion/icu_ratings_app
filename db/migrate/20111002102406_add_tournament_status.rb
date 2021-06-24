class AddTournamentStatus < ActiveRecord::Migration[4.2]
  def change
    add_column :tournaments, :status, :string, default: "ok"
    add_column :tournaments, :stage, :string, limit: 20, default: "unrated"
    add_index  :tournaments, :stage
  end
end
