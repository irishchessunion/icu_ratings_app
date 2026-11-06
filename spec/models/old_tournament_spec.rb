require "rails_helper"

describe OldTournament do
  before(:each) do
    @ot = OldTournament.create!(name: "Old Open", date: Date.new(2010, 4, 11), player_count: 40)
    @hist = OldRatingHistory.create!(old_tournament_id: @ot.id, icu_player_id: FactoryBot.create(:icu_player).id, old_rating: 1800, new_rating: 1820, games: 5, kfactor: 20)
    @other = OldTournament.create!(name: "Other Open", date: Date.new(2011, 5, 12), player_count: 30)
  end

  it "searches by name" do
    result = OldTournament.search({ name: "Old" }, "/path")
    expect(result.matches).to include(@ot)
    expect(result.matches).not_to include(@other)
  end

  it "searches by icu_id" do
    result = OldTournament.search({ icu_id: @hist.icu_player_id }, "/path")
    expect(result.matches).to include(@ot)
    expect(result.matches).not_to include(@other)
  end

  it "returns all when no filters" do
    result = OldTournament.search({}, "/path")
    expect(result.matches).to include(@ot)
  end
end
