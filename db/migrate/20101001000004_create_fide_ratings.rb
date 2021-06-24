class CreateFideRatings < ActiveRecord::Migration[4.2]
  def change
    create_table :fide_ratings do |t|
      t.integer  :fide_player_id
      t.integer  :rating, :games, limit: 2
      t.date     :period

      t.timestamps
    end
    
    add_index :fide_ratings, :fide_player_id
  end
end
