module IcuRatings
  class Seniors
    attr_reader :date

    def initialize(params)
      params[:over] = over_range.first unless params[:over].present? && over_range.include?(params[:over])
      params[:date]  = Date.today.to_s   unless params[:date].present?  && date_range.include?(params[:date])

      @date  = Date.parse(params[:date])
      @over = @date.years_ago(params[:over].to_i)

      @gender = params[:gender]
      @club = params[:club]
    end

    def list
      @list ||= IcuRating.unscoped.maximum(:list)
    end

    def over_range
      @over_range ||= [50, 60, 65].map(&:to_s)
    end

    def date_range
      return @date_range if @date_range
      today = Date.today
      date = today.beginning_of_year
      last = date.next_year
      range = []
      while date <= last
        range.push date
        range.push today if date.year == today.year && date.month == today.month && date.day != today.day
        date = date.next_month
      end
      @date_range = range.map(&:to_s)
    end

    def ratings
      return @ratings if @ratings
      return [] unless available?
      @ratings = IcuRating.unscoped.order("rating DESC, dob DESC").includes(:icu_player).references(:icu_player)
      @ratings = @ratings.where(list: list).where("icu_players.fed = 'IRL' OR icu_players.fed IS NULL")
      @ratings = @ratings.where("icu_players.gender = 'M' OR icu_players.gender IS NULL") if @gender == "M"
      @ratings = @ratings.where("icu_players.gender = 'F'") if @gender == "F"
      @ratings = @ratings.where("icu_players.club = ?", @club) if @club.present?
      @ratings = @ratings.where("icu_players.dob <=  ?", @over)
      @ratings
    end

    def available?
      list ? true : false
    end

    def over_menu
      over_range.map { |y| [y, y] }
    end

    def date_menu
      today = Date.today.to_s
      date_range.inject([]) { |m, d| m.push [d == today ? "Today" : d, d] }
    end
  end
end
