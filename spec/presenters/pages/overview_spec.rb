require 'rails_helper'

describe Pages::Overview do
  before(:each) do
    @reporter = FactoryBot.create(:user, role: "reporter")
    @tournament = Tournament.create!(original_name: "O", name: "O", start: "2026-03-07", finish: "2026-03-08", rorder: 1, rounds: 2, user_id: @reporter.id, stage: "initial", status: "ok")
  end

  it "lists reporters with their tournaments" do
    overview = Pages::Overview.new
    reporters = overview.reporters
    expect(reporters.size).to eq(1)
    expect(reporters.first[:total]).to eq(1)
    expect(reporters.first[:user]).to eq(@reporter)
  end

  it "lists reporters without tournaments" do
    reporter2 = FactoryBot.create(:user, role: "reporter")
    overview = Pages::Overview.new
    reporters = overview.reporters
    expect(reporters.map { |r| r[:user] }).to include(reporter2)
    r2 = reporters.find { |r| r[:user] == reporter2 }
    expect(r2[:total]).to eq(0)
  end

  it "sorts reporters by total descending" do
    overview = Pages::Overview.new
    reporters = overview.reporters
    expect(reporters.first[:total]).to be >= reporters.last[:total]
  end

  it "counts queued, rated, unlocked, and first/next/last tournaments" do
    overview = Pages::Overview.new
    queued = overview.queued
    expect(queued["Queued"][:count]).to be >= 0
    expect(queued["Rated"][:count]).to be >= 0
    expect(queued["Unlocked"][:count]).to be >= 0
  end

  it "counts tournaments, users, icu players and fide players" do
    overview = Pages::Overview.new
    counts = overview.counts
    expect(counts["Tournaments"][:count]).to eq(Tournament.count)
    expect(counts["Users"][:count]).to eq(User.count)
  end

  it "lists problems" do
    overview = Pages::Overview.new
    problems = overview.problems
    expect(problems).to have_key("Tournaments")
    expect(problems).to have_key("Events")
    expect(problems).to have_key("Failures")
  end
end