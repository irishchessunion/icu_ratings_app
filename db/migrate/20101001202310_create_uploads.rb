class CreateUploads < ActiveRecord::Migration[4.2]
  def change
    create_table :uploads do |t|
      t.string   :name, :format, :content_type, :file_type
      t.integer  :size, :tournament_id, :user_id
      t.text     :error
      t.datetime :created_at
    end
    
    add_index :uploads, :tournament_id
    add_index :uploads, :user_id
  end
end
