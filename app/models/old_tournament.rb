# == Schema Information
#
# Table name: old_tournaments
#
#  id           :integer(4)      not null, primary key
#  name         :string(255)
#  date         :date
#  player_count :integer(2)
#

class OldTournament < ApplicationRecord
  extend ICU::Util::Pagination

  has_many :old_rating_histories
  has_many :icu_players, through: :old_rating_histories

  default_scope -> { order(date: :desc, name: :asc) }

  def self.search(params, path)
    matches = all
    if params[:name].present?
      params[:name].strip.split(/\s+/).each do |term|
        matches = matches.where("name LIKE ?", "%#{term}%")
      end
    end
    if params[:icu_id].to_i > 0
      matches = matches.joins(:old_rating_histories).where(old_rating_histories: { icu_player_id: params[:icu_id].to_i })
    end
    paginate(matches, path, params)
  end
end
