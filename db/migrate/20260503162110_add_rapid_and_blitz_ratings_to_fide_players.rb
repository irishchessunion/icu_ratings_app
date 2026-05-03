class AddRapidAndBlitzRatingsToFidePlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :fide_players, :rapid_rating, :integer
    add_column :fide_players, :blitz_rating, :integer
  end
end
