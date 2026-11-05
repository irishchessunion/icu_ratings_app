require 'rails_helper'

describe IcuPlayersHelper do
  it "summarises a personal attribute" do
    p = FactoryBot.create(:icu_player, dob: Date.new(1990, 1, 1))
    expect(helper.summarize(p, :personal)).to include("DOB: 1990-01-01")
  end

  it "returns nil when there's nothing to summarise (gender cleared)" do
    p = FactoryBot.create(:icu_player, gender: nil)
    expect(helper.summarize(p, :personal)).to be_nil
  end

  it "summarises the ICU id with a foreign url" do
    p = FactoryBot.create(:icu_player)
    expect(helper.summarize(p, :icu)).to include("ICU ID")
  end

  it "includes the joined date when present" do
    p = FactoryBot.create(:icu_player, joined: Date.new(2020, 1, 1))
    expect(helper.summarize(p, :icu)).to include("joined: 2020-01-01")
  end

  it "summarises the FIDE id with a link and federation" do
    fp = FactoryBot.create(:fide_player, icu_id: nil, fed: "IRL")
    p = FactoryBot.create(:icu_player)
    p.fide_player = fp
    expect(helper.summarize(p, :fide)).to include("FIDE ID")
  end

  it "summarises only the federation when there's no fide player" do
    p = FactoryBot.create(:icu_player, fed: "IRL")
    expect(helper.summarize(p, :fide)).to eq("federation: IRL")
  end

  it "summarises phones, email, address, deceased, duplicate and note" do
    p = FactoryBot.create(:icu_player, phone_numbers: "home: 123", email: "a@b.com", address: "Dublin", deceased: true, master_id: 99, note: "hello")
    expect(helper.summarize(p, :phones)).to include("Phones:")
    expect(helper.summarize(p, :email)).to include("mailto:")
    expect(helper.summarize(p, :address)).to include("Address:")
    expect(helper.summarize(p, :deceased)).to eq("Deceased")
    expect(helper.summarize(p, :duplicate)).to include("duplicate of 99")
    expect(helper.summarize(p, :note)).to include("Note: hello")
  end

  it "strips the Access database note" do
    p = FactoryBot.create(:icu_player, note: "kept\nFrom Access database extra")
    expect(helper.summarize(p, :note)).to eq("Note: kept")
  end

  it "summarises the old rating" do
    p = FactoryBot.create(:icu_player)
    old = double("OldRating", rating: 1800, type: "full", games: 10)
    allow(p).to receive(:old_rating).and_return(old)
    expect(helper.summarize(p, :old_rating)).to include("Old rating: 1800 (full, 10 games)")
  end

  it "returns nil for :old_rating when there is none" do
    p = FactoryBot.create(:icu_player)
    allow(p).to receive(:old_rating).and_return(nil)
    expect(helper.summarize(p, :old_rating)).to be_nil
  end
end

describe TournamentsHelper do
  it "builds the player id" do
    p = double("Player", id: 42)
    expect(helper.player_id(p)).to eq("P-42")
  end

  it "builds the player class" do
    p = double("Player", id: 42)
    expect(helper.player_class(p)).to eq("player P-42")
  end

  it "builds the result id with and without an opponent" do
    r = double("Result", round: 3, player_id: 7, opponent_id: 9)
    expect(helper.result_id(r)).to eq("R-3-7-9")
    r2 = double("Result", round: 3, player_id: 7, opponent_id: nil)
    expect(helper.result_id(r2)).to eq("R-3-7")
  end

  it "builds the result class" do
    r = double("Result", colour: "W", player_id: 7, opponent_id: 9)
    expect(helper.result_class(r)).to eq("result centered W P-7 P-9")
    r2 = double("Result", colour: nil, player_id: 7, opponent_id: nil)
    expect(helper.result_class(r2)).to eq("result centered P-7")
  end
end

describe PlayersHelper do
  it "picks the right icon for each category" do
    %w[icu_player foreign_player new_player].each do |cat|
      p = double("Player", status_ok?: true, category: cat)
      allow(helper).to receive(:icon_tag).and_return("ICON")
      allow(helper).to receive(:t).and_return(cat)
      expect(helper.category_icon(p)).to eq("ICON")
    end
  end

  it "uses the red flag for a player with problems" do
    p = double("Player", status_ok?: false)
    allow(helper).to receive(:icon_tag).and_return("ICON")
    expect(helper.category_icon(p)).to eq("ICON")
  end

  it "explains the tournament rating" do
    p = double("Player", ave_opp_rating: 1900.0, rateable_games: 4, rateable_score: 2.5)
    expect(helper.explain_trn_rating(p)).to eq("1900.0 + 400 × (2 × 2.5 − 4) ÷ 4")
  end

  it "explains the tournament rating without dividing for one game" do
    p = double("Player", ave_opp_rating: 1900.0, rateable_games: 1, rateable_score: 1.0)
    expect(helper.explain_trn_rating(p)).to eq("1900.0 + 400 × (2 × 1.0 − 1)")
  end

  it "explains the full change, with and without a bonus" do
    p = double("Player", actual_score: 2.5, expected_score: 2.0, k_factor: 32, bonus: 0)
    expect(helper.explain_full_change(p)).to eq("(2.5 − 2.000) × 32")
    p2 = double("Player", actual_score: 2.5, expected_score: 2.0, k_factor: 32, bonus: 10)
    expect(helper.explain_full_change(p2)).to eq("(2.5 − 2.000) × 32 + 10")
  end

  it "explains the full rating and games" do
    p = double("Player", old_rating: 1800, rating_change: 50, old_games: 10, rateable_games: 4)
    expect(helper.explain_full_rating(p)).to eq("1800 + 50")
    expect(helper.explain_full_games(p)).to eq("10 + 4")
  end

  it "explains the provisional rating and games" do
    p = double("Player", old_rating: 1800, old_games: 10, performance_rating: 1900.0, rateable_score: 2.0, rateable_games: 4, new_rating: 1850, new_full: false)
    expect(helper.explain_provisional_rating(p)).to eq("(1800 × 10 + 1900.0 × 4) ÷ (10 + 4)")
    expect(helper.explain_provisional_change(p)).to eq("1850 − 1800")
    expect(helper.explain_provisional_games(p)).to eq("10 + 4 (rating is still provisional)")
  end

  it "explains the provisional games when now full" do
    p = double("Player", old_games: 10, rateable_games: 4, new_full: true)
    expect(helper.explain_provisional_games(p)).to eq("10 + 4 (rating is now full)")
  end

  it "explains the new rating" do
    p = double("Player", ave_opp_rating: 1900.0, rateable_games: 4, rateable_score: 2.5)
    expect(helper.explain_new_rating(p)).to eq("1900.0 + 400 × (2 × 2.5 − 4) ÷ 4")
  end

  it "explains the new games" do
    p = double("Player", new_full: true)
    expect(helper.explain_new_games(p)).to eq("rating is full")
    p2 = double("Player", new_full: false)
    expect(helper.explain_new_games(p2)).to eq("rating is provisional")
  end
end