class ChangeTournamentStage < ActiveRecord::Migration[4.2]
  def up
    change_table :tournaments do |t|
      t.change_default :stage, "scratch"
    end
  end

  def down
    change_table :tournaments do |t|
      t.change_default :stage, "unrated"
    end
  end
end
