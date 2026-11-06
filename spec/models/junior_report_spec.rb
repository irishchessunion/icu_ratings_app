require "rails_helper"

describe JuniorReport do
  before(:each) do
    @player = FactoryBot.create(:icu_player, first_name: "Ann", last_name: "Test", title: "WIM", fed: "IRL", gender: "F", club: "Dublin", email: "ann@example.com", dob: Date.new(2008, 6, 1))
  end

  it "starts the CSV with the header row" do
    expect(JuniorReport.rows.first).to eq("ICU id,Name,Title,Fed,Rating,High Tide,Full?,YOB,M/F,Club,Email,Login users,Phone nr")
  end

  it "writes one row with the player's details, a blank full flag and the login emails" do
    FactoryBot.create(:user, icu_id: @player.id, email: "login@example.com")
    rating = FactoryBot.create(:icu_rating, icu_player: @player, rating: 1650, full: true)
    allow(rating).to receive(:hightide).and_return(1700)
    row = JuniorReport.row(rating)
    expect(row).to eq([@player.id, "\"Test, Ann\"", "WIM", "IRL", 1650, 1700, "", 2008, "F", "\"Dublin\"", "ann@example.com", "login@example.com", @player.phone_numbers.to_s].join(","))
  end

  it "marks a provisional rating as Prov" do
    rating = FactoryBot.create(:icu_rating, icu_player: @player, rating: 1200, full: false)
    allow(rating).to receive(:hightide).and_return(nil)
    # The name is "Test, Ann" in quotes, so it contains a comma: the full flag is column 7 (0-based 7).
    expect(JuniorReport.row(rating).split(",")[7]).to eq("Prov")
  end

  it "joins several login emails with semicolons" do
    FactoryBot.create(:user, icu_id: @player.id, email: "one@example.com")
    FactoryBot.create(:user, icu_id: @player.id, email: "two@example.com")
    expect(JuniorReport.email_addresses_for(@player)).to eq("one@example.com;two@example.com")
  end

  it "writes the header and one row per rating to a file" do
    rating = FactoryBot.create(:icu_rating, icu_player: @player, rating: 1650, full: true)
    allow(rating).to receive(:hightide).and_return(1700)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "junior.csv")
      JuniorReport.generate(path)
      lines = File.read(path).lines
      expect(lines.size).to eq(2)
      expect(lines.first.chomp).to eq("ICU id,Name,Title,Fed,Rating,High Tide,Full?,YOB,M/F,Club,Email,Login users,Phone nr")
      expect(lines.last).to include(@player.id.to_s)
      expect(lines.last).to include("1650")
    end
  end
end
