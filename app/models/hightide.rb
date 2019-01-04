# The hightide module is able to calculate the hightide rating for both an IcuRating and a LiveRating
# It assumes that the including class has the following methods:
#   full?
#   icu_player
#   rating
module Hightide
  def hightide
    if full?
      from = Date.new(Date.today.year, 1, 1)
      to = first_monday_in_may(from.year).next_day
      @hightide ||= icu_player.
          players.
          joins(:tournament).
          where('tournaments.finish between ? and ?', from, to).
          maximum(:new_rating) || rating
    else
      nil
    end
  end

  def first_monday_in_may(year)
    date = Date.new(year, 5, 1)
    until date.monday?
      date = date.next_day
    end
    date
  end
end