require 'rails_helper'

describe Hightide do
  before(:each) do
    allow(Date).to receive(:today).and_return(Date.new(2026, 11, 4))
    @player = FactoryBot.create(:icu_player)
    @tournament_early = Tournament.create!(original_name: "Early", name: "Early", start: "2026-03-01", finish: "2026-03-03", rorder: 1, rounds: 6, user_id: 100, stage: "rated")
    @tournament_late = Tournament.create!(original_name: "Late", name: "Late", start: "2026-05-02", finish: "2026-05-05", rorder: 2, rounds: 6, user_id: 100, stage: "rated")
    @tournament_after = Tournament.create!(original_name: "After", name: "After", start: "2026-05-06", finish: "2026-05-08", rorder: 3, rounds: 6, user_id: 100, stage: "rated")
  end

  def player_in(tournament, new_rating)
    p = Player.new(first_name: "A", last_name: "B", original_name: "B, A", icu_id: @player.id, category: "icu_player", num: 1, bonus: 0, new_rating: new_rating, tournament_id: tournament.id)
    p.save!(validate: false)
    p
  end

  def rating_record(full, rating)
    FactoryBot.create(:icu_rating, icu_player: @player, rating: rating, full: full)
  end

  it "takes the highest new rating from tournaments inside the window" do
    player_in(@tournament_early, 1900)
    player_in(@tournament_late, 1950)
    expect(rating_record(true, 1800).hightide).to eq(1950)
  end

  it "includes a tournament that finishes on the last day of the window, and excludes one after it" do
    player_in(@tournament_after, 2100)
    expect(rating_record(true, 1800).hightide).to eq(1800)
  end

  it "falls back to the current rating when there are no tournaments in the window" do
    expect(rating_record(true, 1777).hightide).to eq(1777)
  end

  it "is nil for a provisional rating" do
    player_in(@tournament_early, 1900)
    expect(rating_record(false, 1800).hightide).to be_nil
  end

  it "finds the first Monday of May" do
    h = Class.new { include Hightide }.new
    expect(h.first_monday_in_may(2026)).to eq(Date.new(2026, 5, 4))
    expect(h.first_monday_in_may(2025)).to eq(Date.new(2025, 5, 5))
  end
end
