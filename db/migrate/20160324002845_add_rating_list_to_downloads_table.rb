class AddRatingListToDownloadsTable < ActiveRecord::Migration[4.2]
  def change
    add_column :downloads, :rating_list_id, :integer
  end
end
