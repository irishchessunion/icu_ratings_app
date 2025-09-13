# == Schema Information
#
# Table name: downloads
#
#  id           :integer(4)      not null, primary key
#  comment      :string(255)
#  file_name    :string(255)
#  content_type :string(255)
#  data         :binary(16777215)
#  created_at   :datetime
#  updated_at   :datetime
#  rating_list_id :integer
#

class Download < ApplicationRecord
  extend ICU::Util::Pagination
  include ICU::Util::Model

  belongs_to :rating_list

  validates_presence_of :data, :content_type, :file_name
  validates_length_of   :data, maximum: 1.megabyte
  validates_length_of   :comment, maximum: 80
  
  def uploaded_file=(file)
    self.file_name    = base_part_of(file.original_filename)
    self.content_type = file.content_type.chomp
    self.data         = file.read
  end

  def rating_list_date
    if rating_list.present?
      rating_list.date
    end
  end

  def self.search(params, path)
    matches = includes(:rating_list).order(updated_at: :desc)
    paginate(matches, path, params)
  end

  # Produces an export of all the current players and their data
  # @param list String/symbol that determines if the published/live ratings are used
  # @return An instance of Axlsx::Package
  def self.rating_list_xlsx(list)
    year = Time.now.year
    month = Time.now.month

    # New season starts in August
    if month < 8
      year -= 1
    end

    this_season = "#{year}-#{(year+1).to_s[-2..]}"
    last_season = "#{year-1}-#{(year).to_s[-2..]}"

    # Get latest rating list
    last_list = IcuRating.maximum("list")
    
    # Calculate cut-off date for tournaments to count towards that list
    tournament_cut_off = RatingList.where("date = ?", last_list).first().tournament_cut_off

    # Calculate latest tournament before cut-off date
    last_tournament_rorder = Tournament.where("finish <= ? AND stage = 'rated' AND rorder IS NOT NULL",
      tournament_cut_off).maximum("rorder")

    # Get players, subs and ratings
    icu_players = IcuPlayer.where("deceased = 0 AND master_id IS NULL")
    subscriptions = Subscription.where("season IN (?, ?) OR category = 'lifetime'", this_season, last_season)
    ratings = Player.select(:icu_id, :new_rating)
      .where("icu_id IS NOT NULL AND new_rating IS NOT NULL")
      .joins(:tournament)
    
    if list == 'published' or list == :published
      ratings = ratings.where("rorder <= ?", last_tournament_rorder)
    elsif list == 'live' or list == :live
      ratings = ratings.where("rorder IS NOT NULL")
    else 
      raise "unknown list"
    end
    ratings = ratings.order(rorder: :desc)
    
    rows = []
    for player in icu_players
      title = case player.title
        when nil, '' then ''
        when 'GM' then 'g'
        when 'IM' then 'i'
        when 'FM' then 'f'
        when 'CM' then 'c'
        else '?'
      end

      # It is possible to use player.latest_rating for the published list but not for the live rating
      latest_rating = ratings.where(icu_id: player.id).first()&.new_rating

      # Get fide ID and rating
      fide_id = player.fide_player&.id
      fide_rating = player.fide_player&.rating
      
      # L = lifetime
      # U = unpaid
      # S = paid for current season
      # P = paid for previous season
      sub = 'L'
      sub = case subscriptions.where(icu_id: player.id).order(season: :desc).first()&.season
        when this_season then 'S'
        when last_season then 'P'
        else 'U'
      end unless not subscriptions.where(icu_id: player.id, category: 'lifetime').first().nil?

      # Swiss Manager expects F for female and nothing for male
      sex = player.gender == "F" ? "F": ""

      # Outputs YOB/01/01 to hide DOB
      dob = player.dob ? Date.new(player.dob.year, 1, 1).strftime("%Y/%m/%d") : '1900/01/01'

      rows << [player.id, fide_id, player.name, title, player.fed, latest_rating, fide_rating, 0, dob, sub, sex, player.club]
    end

    # Sort by name ascending
    rows.sort_by! {|e| e[2]}

    axlsx_package = Axlsx::Package.new
    axlsx_package.workbook.add_worksheet(:name => "#{list.capitalize} Rating List") do |sheet|
      sheet.add_row %w(ID_no Fide_no Name Title Fed Rtg_Nat Rtg_Int Games Birthday Sub Sex ClubName)
      for row in rows
        sheet.add_row row
      end
    end

    axlsx_package
  end
end
