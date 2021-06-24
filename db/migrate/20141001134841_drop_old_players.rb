class DropOldPlayers < ActiveRecord::Migration[4.2]
  def up
    drop_table :old_players
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Old player data is now in www_production.players (status: inactive, source: archive)"
  end
end
