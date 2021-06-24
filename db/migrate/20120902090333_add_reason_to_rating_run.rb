class AddReasonToRatingRun < ActiveRecord::Migration[4.2]
  def change
    add_column :rating_runs, :reason, :string, limit: 100, default: "", null: false
  end
end
