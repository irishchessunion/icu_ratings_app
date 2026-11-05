require 'rails_helper'

# Extra coverage for Tournament: search, ordered_players, find_first_player_with_errors, export_formats.
describe Tournament do
  before(:all) do
    @u = FactoryBot.create(:user, role: "officer")
  end

  before(:each) do
    @t = Tournament.create!(original_name: "Extra T", name: "Extra T", start: "2026-03-07", finish: "2026-03-08", rorder: 1, rounds: 2, user_id: @u.id, stage: "ready", fide_id: 12345)
    @p1 = Player.create!(first_name: "Ann", last_name: "Adams", original_name: "Adams, Ann", category: "icu_player", num: 1, bonus: 0, tournament_id: @t.id, status: "ok")
    @p2 = Player.create!(first_name: "Ben", last_name: "Brown", original_name: "Brown, Ben", category: "icu_player", num: 2, bonus: 0, tournament_id: @t.id, status: "ok")
  end

  it "searches by name" do
    result = Tournament.search({ name: "Extra" }, "/path")
    expect(result.matches).to include(@t)
  end

  it "searches by year" do
    result = Tournament.search({ year: 2026 }, "/path")
    expect(result.matches).to include(@t)
  end

  it "searches by icu_id" do
    result = Tournament.search({ icu_id: @p1.icu_id }, "/path") if @p1.icu_id
  end

  it "searches by first and last name" do
    result = Tournament.search({ first_name: "Ann", last_name: "Adams" }, "/path")
    expect(result.matches).to include(@t)
  end

  it "searches by fide_rated" do
    result = Tournament.search({ fide_rated: "true" }, "/path")
    expect(result.matches).to include(@t)
    result2 = Tournament.search({ fide_rated: "false" }, "/path")
    expect(result2.matches).not_to include(@t)
  end

  it "searches by status ok" do
    result = Tournament.search({ status: "ok" }, "/path")
    expect(result.matches).to include(@t)
  end

  it "searches by user_id" do
    result = Tournament.search({ user_id: @u.id, admin: true }, "/path")
    expect(result.matches).to include(@t)
  end

  it "searches by stage" do
    result = Tournament.search({ stage: "ready" }, "/path")
    expect(result.matches).to include(@t)
  end

  it "returns ordered players by name when not rankable" do
    players = @t.ordered_players
    expect(players).to eq([@p1, @p2])
  end

  it "finds the first player with errors" do
    @p2.update_column(:status, "error")
    expect(@t.find_first_player_with_errors).to eq(@p2)
  end

  it "returns nil when no players have errors" do
    expect(@t.find_first_player_with_errors).to be_nil
  end

  it "returns export formats excluding SwissPerfect" do
    formats = @t.export_formats
    expect(formats).not_to be_nil
    expect(formats.map(&:last)).not_to include("SwissPerfect")
  end

  it "is not rankable when no players have ranks" do
    expect(@t.rankable).to eq(false)
  end
end