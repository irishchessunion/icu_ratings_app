class AddFirstRatedMsecToTournaments < ActiveRecord::Migration[5.0]
  def up
    change_table :tournaments do |t|
      t.integer :first_rated_msec, limit: 2, default: 0
    end
  end

  def down
    change_table :tournaments do |t|
      t.remove :first_rated_msec
    end
  end

end
