# == Schema Information
#
# Table name: subscriptions
#
# integer  "icu_id"
# string   "season",      :limit => 7
# string   "category",    :limit => 8
# pay_date "date"
# datetime "created_at",  :null => false
# datetime "updated_at",  :null => false
#

class Subscription < ApplicationRecord
  extend ICU::Util::Pagination
  CATEGORY = %w(online offline lifetime)
  LAST_MONTH_IN_SEASON = 8 # August

  belongs_to :icu_player, foreign_key: "icu_id"

  validates :icu_id, numericality: { only_integer: true, greater_than: 0 }
  validates :season, format: { with: /\A20\d\d-\d\d\z/ }, :if => Proc.new { |sub| sub.category != "lifetime" }
  validates :category, inclusion: { :in => CATEGORY, message: "%{value} is not a valid category" }
  validates :pay_date, date: { on_or_after: "2006-08-01" }, allow_nil: true

  def self.search(params, path)
    matches = joins(:icu_player).includes(:icu_player)
    matches = matches.order("icu_players.last_name, icu_players.first_name, subscriptions.season DESC, subscriptions.category")
    matches = matches.where("icu_players.last_name LIKE ?", "%#{params[:last_name]}%") if params[:last_name].present?
    matches = matches.where("icu_players.first_name LIKE ?", "%#{params[:first_name]}%") if params[:first_name].present?
    matches = matches.where(season: params[:season]) if params[:season].present?
    matches = matches.where(category: params[:category]) if params[:category].present?
    matches = matches.where(icu_id: params[:icu_id].to_i) if params[:icu_id].to_i > 0
    paginate(matches, path, params)
  end

  def self.season(time=nil)
    time ||= Time.now
    year = time.year
    year-= 1 if time.month <= LAST_MONTH_IN_SEASON
    "#{year}-#{year - 1999}"
  end

  def self.last_season(time=nil)
    time ||= Time.now
    season(time.prev_year)
  end

  def self.next_season(time=nil)
    time ||= Time.now
    season(time.next_year)
  end

  def self.get_subs(season, cut_off, last_season=nil)
    current = where("category = 'lifetime' OR (season = ? AND (pay_date IS NULL OR pay_date <= ?))", season, cut_off).to_a
    previous = []
    if last_season
      icu_ids = current.map(&:icu_id)
      if icu_ids.empty?
        previous = where("season = ?", last_season).to_a
      else
        previous = where("season = ? AND icu_id NOT IN (?)", last_season, icu_ids).to_a
      end
    end
    current + previous
  end

  def self.get_active_subs(time=nil, payment_cutoff=nil)
    time ||= Time.now
    payment_cutoff ||= Time.now
    last_season = time.month > LAST_MONTH_IN_SEASON ? self.last_season(time) : nil
    get_subs(self.season(time), payment_cutoff, last_season)
  end

end
