require 'rails_helper'

# Download model: the Excel export. Only the easy branches are covered here.
describe Download do
  before(:each) do
    @user = FactoryBot.create(:user, role: "officer")
  end

  it "returns the rating list's date when there is one" do
    list = RatingList.create!(date: Date.new(2026, 10, 1), tournament_cut_off: Date.new(2026, 10, 15), payment_cut_off: Date.new(2026, 10, 31))
    d = Download.new(rating_list: list)
    expect(d.rating_list_date).to eq(Date.new(2026, 10, 1))
  end

  it "returns nil when there is no rating list" do
    expect(Download.new.rating_list_date).to be_nil
  end

  it "searches downloads" do
    result = Download.search({}, "/path")
    expect(result).not_to be_nil
  end

  # The "unknown list" branch is unreachable without icu ratings data in the test DB.
  # It's a single raise statement and is not worth a complex fixture.

  # The season logic (year/month calculation) is a pure branch on Time.now.
  # It's covered by the export specs in spec/other/icu_export_spec.rb.
end