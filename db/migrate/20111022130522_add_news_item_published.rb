class AddNewsItemPublished < ActiveRecord::Migration[4.2]
  def change
    add_column :news_items, :published, :boolean, default: false
    add_index  :news_items, :published
  end
end
