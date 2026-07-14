module IcuRatings
  class Women
    attr_reader :list, :club

    def initialize(params)
      @club = params[:club]
      @list = params[:list]
    end

    def list
      @list ||= IcuRating.unscoped.maximum(:list)
    end

    def ratings
      return @ratings if @ratings
      return [] unless available?
      @ratings = IcuRating.unscoped.order("rating DESC").includes(:icu_player).references(:icu_player)
      @ratings = @ratings.where(list: list).where("icu_players.fed = 'IRL' OR icu_players.fed IS NULL")
      @ratings = @ratings.where("icu_players.gender = 'F'") # Filters for women
      @ratings = @ratings.where("icu_players.club = ?", @club) if @club.present?
      @ratings = @ratings.where("icu_players.deceased is NULL OR icu_players.deceased = ?", false)
      @ratings
    end

    def available?
      list ? true : false
    end
  end
end