# The hightide module is able to calculate the hightide rating for both an IcuRating and a LiveRating
# It assumes that the including class has the following methods:
#   full?
#   icu_player
#   rating
module Hightide
  FROM = Date.new(2016, 1, 1)
  TO = Date.new(2016, 5, 2)

  def hightide
    if full?
      @hightide ||= icu_player.
          players.
          joins(:tournament).
          where('tournaments.finish between ? and ?', FROM, TO).
          maximum(:new_rating) || rating
    else
      nil
    end
  end
end