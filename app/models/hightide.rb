# The hightide module is able to calculate the hightide rating for both an IcuRating and a LiveRating
# It assumes that the including class has the following methods:
#   full?
#   icu_player
#   rating
module Hightide
  THIS_YEAR = 2018 # Date.today.year # Use Date.today.year only if you remember to reboot the server on January 1st.
  FROM = Date.new(THIS_YEAR, 1, 1)
  TO = Date.new(THIS_YEAR, 5, 7)

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