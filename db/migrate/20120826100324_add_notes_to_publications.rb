class AddNotesToPublications < ActiveRecord::Migration[4.2]
  def change
    add_column :publications, :notes, :text
  end
end
