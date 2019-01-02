# The hightide module is able to calculate the hightide rating for both an IcuRating and a LiveRating
# It assumes that the including class has the following methods:
#   full?
#   icu_player
#   rating
module Hightide
  def hightide
    if full?
      from = Date.new(Date.today.year, 1, 1)
      to = Date.new(from.year, 5, 7)
      @hightide ||= icu_player.
          players.
          joins(:tournament).
          where('tournaments.finish between ? and ?', from, to).
          maximum(:new_rating) || rating
    else
      nil
    end
  end
end