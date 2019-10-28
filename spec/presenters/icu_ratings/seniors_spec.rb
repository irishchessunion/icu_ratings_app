require 'rails_helper'

module IcuRatings
  describe Seniors do
    describe "insufficient data" do
      it "should be unavailable" do
        j = Seniors.new({})
        expect(j.available?).to be false
        expect(j.ratings).to be_empty
      end
    end

    describe "enough data" do
      before(:each) do
        allow(Date).to receive(:today).and_return(Date.new(2011, 12, 17))
        @list = "2011-09-01"
        @p1 = FactoryBot.create(:icu_player, dob: "1950-08-02", gender: "F")
        @p2 = FactoryBot.create(:icu_player, dob: "1940-08-01")
        @p3 = FactoryBot.create(:icu_player, dob: "1960-01-01")
        @p4 = FactoryBot.create(:icu_player, dob: "1970-05-31")
        @p5 = FactoryBot.create(:icu_player, dob: "1940-06-01", fed: "RUS")
        @r1 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p1)
        @r5 = FactoryBot.create(:icu_rating, list: "2011-05-01", icu_player: @p1)
        @r2 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p2)
        @r3 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p3)
        @r4 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p4)
        @r6 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p5)
      end

      it "default settings" do
        params = {}
        j = Seniors.new(params)
        expect(j.available?).to be true
        expect(params[:date]).to eq("2011-12-17")
        expect(params[:over]).to eq("50")
        expect(j.list.to_s).to eq(@list)
        ratings = j.ratings
        expect(ratings.size).to eq(3)
        expect(ratings).to include(@r1)
        expect(ratings).to include(@r2)
        expect(ratings).to include(@r3)
        date_range = j.date_range
        expect(date_range.size).to eq(14)
        expect(date_range.first).to eq("2011-01-01")
        expect(date_range.last).to eq("2012-01-01")
      end

      it "narrow age range" do
        j = Seniors.new(date: "2011-09-01", over: "60")
        ratings = j.ratings
        expect(ratings.size).to eq(2)
        expect(ratings).to include(@r1)
        expect(ratings).to include(@r2)
      end
    end

  end
end
