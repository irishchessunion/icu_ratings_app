class AddIdentifierToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :identity, :string, length: 32
  end
end
