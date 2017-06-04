json.array! @icu_ratings.matches do |icu_rating|
  json.icu_id icu_rating.icu_id
  json.first_name icu_rating.icu_player ? icu_rating.icu_player.first_name : "Unknown"
  json.last_name icu_rating.icu_player ? icu_rating.icu_player.last_name : "Unknown"
  json.club icu_rating.icu_player ? icu_rating.icu_player.club : ""
  json.federation icu_rating.icu_player ? icu_rating.icu_player.fed : ""
  json.rating icu_rating.rating
  json.list year_month(icu_rating.list)
  json.fide_id icu_rating.icu_player && icu_rating.icu_player && icu_rating.icu_player.fide_player && icu_rating.icu_player.fide_player.id
end
