class CreateDownloads < ActiveRecord::Migration[4.2]
  def change
    create_table :downloads do |t|
      t.string :comment
      t.string :file_name
      t.string :content_type
      t.binary :data, limit: 1.megabyte

      t.timestamps
    end
  end
end
