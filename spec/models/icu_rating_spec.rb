require 'rails_helper'

describe IcuRating do
  before(:each) do
    @player = FactoryBot.create(:icu_player, first_name: "Ann", last_name: "Adams", fed: "IRL", gender: "F", club: "Dublin")
    @rating = FactoryBot.create(:icu_rating, icu_player: @player, rating: 1500, full: true, list: Date.new(2026, 10, 1))
  end

  it "searches by name" do
    result = IcuRating.search({ first_name: "Ann", last_name: "Adams" }, "/path")
    expect(result.matches).to include(@rating)
  end

  it "searches by club" do
    result = IcuRating.search({ club: "Dublin" }, "/path")
    expect(result.matches).to include(@rating)
  end

  it "searches by club None" do
    player2 = FactoryBot.create(:icu_player, first_name: "Ben", last_name: "Brown", club: nil)
    rating2 = FactoryBot.create(:icu_rating, icu_player: player2, rating: 1600, full: true, list: Date.new(2026, 10, 1))
    result = IcuRating.search({ club: "None" }, "/path")
    expect(result.matches).to include(rating2)
  end

  it "searches by gender" do
    result = IcuRating.search({ gender: "F" }, "/path")
    expect(result.matches).to include(@rating)
  end

  it "searches by type" do
    result = IcuRating.search({ type: "full" }, "/path")
    expect(result.matches).to include(@rating)
  end

  it "searches by icu_id" do
    result = IcuRating.search({ icu_id: @player.id }, "/path")
    expect(result.matches).to include(@rating)
  end

  it "searches by list" do
    result = IcuRating.search({ list: "2026-10-01" }, "/path")
    expect(result.matches).to include(@rating)
  end

  it "searches by fed" do
    result = IcuRating.search({ fed: "IRL" }, "/path")
    expect(result.matches).to include(@rating)
  end

  it "returns all when no filters" do
    result = IcuRating.search({}, "/path")
    expect(result.matches).to include(@rating)
  end

  it "gets the latest rating" do
    expect(IcuRating.get_rating(@player.id, :latest)).to eq(@rating)
  end

  it "gets the highest rating" do
    expect(IcuRating.get_rating(@player.id, :highest)).to eq(@rating)
  end

  it "gets the lowest rating" do
    expect(IcuRating.get_rating(@player.id, :lowest)).to eq(@rating)
  end

  it "exports to CSV" do
    csv = IcuRating.to_csv([@rating])
    expect(csv).to include("Adams")
    expect(csv).to include("Ann")
  end

  it "lists distinct lists" do
    expect(IcuRating.lists).to include(Date.new(2026, 10, 1))
  end

  it "gives the type" do
    expect(@rating.type).to eq("full")
    expect(FactoryBot.create(:icu_rating, icu_player: FactoryBot.create(:icu_player), rating: 1200, full: false, list: Date.new(2026, 10, 1)).type).to eq("provisional")
  end

  it "gives the original type" do
    expect(@rating.original_type).to eq("full")
  end
end