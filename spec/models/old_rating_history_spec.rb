require "rails_helper"

# OldRatingHistory.search: a player's history (newest tournament first), a tournament's
# players (by surname), or the first 100 rows when there's no filter.
describe OldRatingHistory do
  before(:each) do
    @ann = FactoryBot.create(:icu_player, first_name: "Ann", last_name: "Adams")
    @ben = FactoryBot.create(:icu_player, first_name: "Ben", last_name: "Brown")
    @older = OldTournament.create!(name: "Old Open", date: Date.new(2009, 4, 11), player_count: 40)
    @newer = OldTournament.create!(name: "New Open", date: Date.new(2010, 4, 11), player_count: 50)
    @ann_old = OldRatingHistory.create!(old_tournament_id: @older.id, icu_player_id: @ann.id, old_rating: 1700, new_rating: 1720, games: 5, kfactor: 20)
    @ann_new = OldRatingHistory.create!(old_tournament_id: @newer.id, icu_player_id: @ann.id, old_rating: 1720, new_rating: 1750, games: 6, kfactor: 20)
    @ben_new = OldRatingHistory.create!(old_tournament_id: @newer.id, icu_player_id: @ben.id, old_rating: 1500, new_rating: 1480, games: 4, kfactor: 20)
  end

  def search(params)
    OldRatingHistory.search(params, "/path").to_a
  end

  it "returns one player's history, newest tournament first" do
    expect(search(icu_player_id: @ann.id)).to eq([@ann_new, @ann_old])
  end

  it "returns one tournament's players, ordered by surname" do
    expect(search(old_tournament_id: @newer.id)).to eq([@ann_new, @ben_new])
  end

  it "returns the first 100 rows when there's no filter" do
    expect(search({}).size).to eq(3)
  end

  it "ignores a non-numeric player filter and falls back to the unfiltered list" do
    expect(search(icu_player_id: "abc").size).to eq(3)
  end

  it "paginates when a page size is given" do
    result = OldRatingHistory.search({ per_page: 2 }, "/path")
    expect(result).to be_a(ICU::Util::Paginator)
    expect(result.total).to eq(3)
    expect(result.matches.to_a.size).to eq(2)
  end

  it "gives the rating change as the new rating less the old" do
    expect(@ann_new.rating_change).to eq(30)
    expect(@ben_new.rating_change).to eq(-20)
  end
end
