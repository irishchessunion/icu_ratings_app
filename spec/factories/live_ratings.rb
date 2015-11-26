FactoryGirl.define do
  factory :live_rating do
    association      :icu_player
    rating           { 1 + rand(2400) }
    full             true
    last_rating  { rating + (rand(3) - 1) * rand(20) }
    last_full    true
    games { rand(4) }
  end
end
