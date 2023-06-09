class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string   :email, :preferred_email, limit: 50
      t.string   :password, limit: 20
      t.string   :role, limit: 20, default: "member"
      t.integer  :icu_id
      t.date     :expiry

      t.timestamps
    end
    
    add_index :users, :email, unique: true
  end
end
