require 'rails_helper'

module IcuRatings
  describe Women do
    describe "insufficient data" do
      it "should be unavailable" do
        w = Women.new({})
        expect(w.available?).to be false
        expect(w.ratings).to be_empty
      end
    end

    describe "enough data" do
      before(:each) do
        @list = "2011-09-01"
        @p1 = FactoryBot.create(:icu_player, gender: "F")
        @p2 = FactoryBot.create(:icu_player, gender: "F", club: "Bray")
        @p3 = FactoryBot.create(:icu_player, gender: "M")
        @p4 = FactoryBot.create(:icu_player, gender: "F", fed: "ENG")
        @p5 = FactoryBot.create(:icu_player, gender: nil)
        @r1 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p1, rating: 1500)
        @r2 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p2, rating: 1800)
        @r3 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p3, rating: 2000)
        @r4 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p4, rating: 1900)
        @r5 = FactoryBot.create(:icu_rating, list: @list, icu_player: @p5, rating: 1700)
        @r6 = FactoryBot.create(:icu_rating, list: "2011-05-01", icu_player: @p1, rating: 2100)
      end

      it "default settings" do
        params = {}
        w = Women.new(params)
        expect(w.available?).to be true
        expect(w.list.to_s).to eq(@list)
        ratings = w.ratings
        expect(ratings.size).to eq(2)
        expect(ratings).to include(@r1)
        expect(ratings).to include(@r2)
      end

      it "excludes men and players without a gender" do
        ratings = Women.new({}).ratings
        expect(ratings).not_to include(@r3)
        expect(ratings).not_to include(@r5)
      end

      it "excludes ratings from a different list" do
        ratings = Women.new({}).ratings
        expect(ratings).not_to include(@r6)
      end

      it "excludes foreign federations" do
        ratings = Women.new({}).ratings
        expect(ratings).not_to include(@r4)
      end

      it "orders by rating descending" do
        ratings = Women.new({}).ratings
        expect(ratings.first).to eq(@r2)
        expect(ratings.second).to eq(@r1)
      end

      it "filters by club" do
        w = Women.new(club: "Bray")
        ratings = w.ratings
        expect(ratings.size).to eq(1)
        expect(ratings).to include(@r2)
      end

      it "uses a given list instead of the latest one" do
        w = Women.new(list: "2011-05-01")
        ratings = w.ratings
        expect(ratings.size).to eq(1)
        expect(ratings).to include(@r6)
      end
    end
  end
end
