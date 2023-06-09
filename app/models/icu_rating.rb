# == Schema Information
#
# Table name: icu_ratings
#
#  id              :integer(4)      not null, primary key
#  list            :date
#  icu_id          :integer(4)
#  rating          :integer(2)
#  full            :boolean(1)      default(FALSE)
#  original_rating :integer(2)
#  original_full   :boolean(2)
#

class IcuRating < ApplicationRecord
  extend ICU::Util::Pagination
  include Hightide

  belongs_to :icu_player, foreign_key: "icu_id"

  validates :rating, numericality: { only_integer: true }
  validates :full, inclusion: { in: [true, false] }
  validates :original_rating, numericality: { only_integer: true }, allow_nil: true
  validates :original_full, inclusion: { in: [true, false] }, allow_nil: true
  validates :list, date: { on_or_after: "2001-09-01", on_or_before: :today }
  validates :list, list_date: true

  default_scope -> { includes(:icu_player).joins(:icu_player).order("list DESC, rating DESC, icu_players.last_name") }

  def self.search(params, path, paginated=true)
    matches = all
    matches = matches.where("first_name LIKE ?", "%#{params[:first_name]}%") if params[:first_name].present?
    matches = matches.where("last_name LIKE ?", "%#{params[:last_name]}%") if params[:last_name].present?
    matches = matches.where("club IS NULL") if params[:club] == "None"
    matches = matches.where("club = ?", params[:club]) if params[:club].present? && params[:club] != "None"
    matches = matches.where("gender = 'M' OR gender IS NULL") if params[:gender] == "M"
    matches = matches.where("gender = 'F'") if params[:gender] == "F"
    matches = matches.where(icu_id: params[:icu_id].to_i) if params[:icu_id].to_i > 0
    matches = matches.where(full: params[:type] == "full") if params[:type].present?
    matches = matches.where(list: params[:list]) if params[:list].present?
    matches = IcuPlayer.search_fed(matches, params[:fed])
    return matches unless paginated
    paginate(matches, path, params)
  end

  def self.get_rating(icu_id, type)
    match = unscoped
    match = match.where(icu_id: icu_id)
    case type
    when :latest  then match = match.order(list: :desc)
    when :highest then match = match.order(rating: :desc, list: :asc)
    when :lowest  then match = match.order(rating: :asc, list: :asc)
    end
    match.first
  end

  def self.to_csv(ratings)
    CSV.generate do |csv|
      csv << %w[last first id list rating provisional federation club]
      ratings.each do |r|
        if p = r.icu_player
          csv << [p.last_name, p.first_name, r.icu_id, r.list, r.rating, !r.full, p.fed, p.club]
        end
      end
    end
  end

  def self.hightide_query
    'SELECT MAX(players.new_rating) FROM players INNER JOIN tournaments ON tournaments.id = players.tournament_id WHERE players.icu_id = icu_ratings.icu_id AND (tournaments.finish between ? and ?)'
  end

  def type
    full ? "full" : "provisional"
  end

  def original_type
    original_full ? "full" : "provisional"
  end

  def self.lists
    unscoped.select("DISTINCT(list)").order(list: :desc).map(&:list)
  end
end
