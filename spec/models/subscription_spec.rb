require 'rails_helper'

describe Subscription do
  before(:each) do
    @s13 = Subscription.create(icu_id: 1, season: "2012-13", pay_date: Time.new(2012, 10,  5), category: "offline")
    @s14 = Subscription.create(icu_id: 2, season: "2013-14", pay_date: Time.new(2014,  4,  5), category: "offline")
    @s15 = Subscription.create(icu_id: 3, season: "2014-15", pay_date: Time.new(2014,  8,  5), category: "offline")
  end

  context "#season" do
    it "should convert a date to the current season" do
      expect(Subscription.season(Time.new(2012,7,21))).to eq("2011-12")
      expect(Subscription.season(Time.new(2012,8,31))).to eq("2011-12")
      expect(Subscription.season(Time.new(2012,9,1))).to eq("2012-13")
      expect(Subscription.season(Time.new(2012,12,31))).to eq("2012-13")
      expect(Subscription.season(Time.new(2013,1,1))).to eq("2012-13")
    end
  end

  context "#last_season" do
    it "should convert a date to the last season" do
      expect(Subscription.last_season(Time.new(2012,7,21))).to eq("2010-11")
      expect(Subscription.last_season(Time.new(2012,8,31))).to eq("2010-11")
      expect(Subscription.last_season(Time.new(2012,9,1))).to eq("2011-12")
      expect(Subscription.last_season(Time.new(2012,9,31))).to eq("2011-12")
      expect(Subscription.last_season(Time.new(2012,10,1))).to eq("2011-12")
      expect(Subscription.last_season(Time.new(2012,12,31))).to eq("2011-12")
      expect(Subscription.last_season(Time.new(2013,1,1))).to eq("2011-12")
    end
  end

  context "#get_active_subs" do
    it "should have correct subs in September" do
      subs = Subscription.get_active_subs(Time.new(2014, 9, 1))
      expect(subs).to_not include(@s13)
      expect(subs).to include(@s14)
      expect(subs).to include(@s15)
    end

    it "should have correct subs in January" do
      subs = Subscription.get_active_subs(Time.new(2015, 1, 1))
      expect(subs).to_not include(@s13)
      expect(subs).to_not include(@s14)
      expect(subs).to include(@s15)
    end
  end

end
