# The hightide module is able to calculate the hightide rating for both an IcuRating and a LiveRating
# It assumes that the including class has the following methods:
#   full?
#   icu_player
#   rating
module Hightide
  # @param from [Date]
  # @param to [Date]
  def hightide(from, to)
    if full?
      icu_player.
          players.
          joins(:tournament).
          where('tournaments.finish between ? and ?', from, to).
          maximum(:new_rating) || rating
    else
      nil
    end
  end
end