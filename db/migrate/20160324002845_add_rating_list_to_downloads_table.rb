class AddRatingListToDownloadsTable < ActiveRecord::Migration
  def change
    add_column :downloads, :rating_list_id, :integer
  end
end
