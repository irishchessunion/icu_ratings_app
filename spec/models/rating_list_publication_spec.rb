require "rails_helper"

# Publication edge cases for RatingList that the end-to-end specs in rating_list_spec.rb
# don't reach. Every expected value was worked out by hand from the rules.
describe RatingList do
  def make_list(date, cut_off, payment)
    RatingList.create!(date: date, tournament_cut_off: cut_off, payment_cut_off: payment)
  end

  def lifetime_sub(icu_id)
    Subscription.create!(icu_id: icu_id, category: "lifetime")
  end

  def save_player(tournament, attrs)
    p = Player.new({ category: "icu_player", num: 1, bonus: 0, old_games: 0, new_games: 0, tournament_id: tournament.id,
                     original_name: "x", last_name: "x", first_name: "x" }.merge(attrs))
    p.save!(validate: false)
    p
  end

  describe "#add_to_changes" do
    before(:each) { @list = make_list(Date.new(2026, 10, 1), Date.new(2026, 10, 15), Date.new(2026, 10, 31)) }

    def bucket_for(old, new)
      h = Hash.new { |hash, k| hash[k] = [] }
      @list.send(:add_to_changes, h, old, new, 1)  # private helper, tested directly
      h.keys.first
    end

    it "puts a zero change in 'no change'" do
      expect(bucket_for(1500, 1500)).to eq("no change")
    end

    it "groups small increases in tens" do
      expect(bucket_for(1500, 1501)).to eq("increase of 1-10")
      expect(bucket_for(1500, 1510)).to eq("increase of 1-10")
      expect(bucket_for(1500, 1511)).to eq("increase of 11-20")
      expect(bucket_for(1500, 1520)).to eq("increase of 11-20")
    end

    it "groups decreases in tens, with the direction in the name" do
      expect(bucket_for(1520, 1500)).to eq("decrease of 11-20")
      expect(bucket_for(1510, 1500)).to eq("decrease of 1-10")
    end

    it "uses 91-100 for a change of exactly 100, and 'more than 100' from 101" do
      expect(bucket_for(1500, 1600)).to eq("increase of 91-100")
      expect(bucket_for(1500, 1601)).to eq("increase > 100")
      expect(bucket_for(1500, 1400)).to eq("decrease of 91-100")
      expect(bucket_for(1601, 1500)).to eq("decrease > 100")
    end
  end

  describe "#next_list, #prev_list and .last_list" do
    it "finds the neighbouring lists and the most recent one" do
      aug = make_list(Date.new(2026, 8, 1), Date.new(2026, 8, 15), Date.new(2026, 8, 31))
      sep = make_list(Date.new(2026, 9, 1), Date.new(2026, 9, 15), Date.new(2026, 9, 30))
      oct = make_list(Date.new(2026, 10, 1), Date.new(2026, 10, 15), Date.new(2026, 10, 31))
      expect(sep.next_list).to eq(oct)
      expect(sep.prev_list).to eq(aug)
      expect(aug.prev_list).to be_nil
      expect(oct.next_list).to be_nil
      expect(RatingList.last_list).to eq(oct)
      expect(oct.last_list?).to be true
      expect(sep.last_list?).to be false
    end
  end

  describe "#publish" do
    before(:each) do
      @list = make_list(Date.new(2026, 10, 1), Date.new(2026, 10, 15), Date.new(2026, 10, 31))
      @today = Date.new(2026, 10, 20) # same month as the list, so original ratings are reset

      # Ratings on a list are only visible when there's a matching icu_players row (IcuRating's default scope joins it).
      (2001..2009).each { |id| IcuPlayer.create!(id: id, first_name: "Player", last_name: "No#{id}", deceased: false) }

      # An older rated tournament, needed because ratings before the March 2024 adjustment come from it.
      @t0 = Tournament.new(original_name: "Old", name: "Old", start: "2023-09-08", finish: "2023-09-10", rorder: 1, rounds: 6, user_id: 100, stage: "rated")
      @t0.save!
      # The tournament used for this list: finishes before the cut-off, so it's the last one used.
      @t1 = Tournament.new(original_name: "Rated 1", name: "Rated 1", start: "2026-09-18", finish: "2026-09-20", rorder: 2, rounds: 6, user_id: 100, stage: "rated")
      @t1.save!
    end

    def subscribe(*icu_ids)
      icu_ids.each { |id| lifetime_sub(id) }
    end

    def earlier_publication!
      @list.publications.create!(total: 0, creates: 0, remains: 0, updates: 0, deletes: 0, report: "earlier", last_tournament_id: @t1.id)
    end

    context "with a full set of changes" do
      before(:each) do
        # Subscribed: 2001 to 2004 and 2006 to 2009. Not 2005, whose subscription has lapsed.
        subscribe(2001, 2002, 2003, 2004, 2006, 2007, 2008, 2009)

        # 2001: legacy rating of 350, below the floor of 400.
        OldRating.create!(icu_id: 2001, rating: 350, full: false, games: 5)

        # 2002: rated in tournament 1, full rating.
        save_player(@t1, icu_id: 2002, new_rating: 1800, new_full: true)
        # 2006 to 2009: rated in tournament 1 at 1520, 1500, 1000 and 1505.
        save_player(@t1, icu_id: 2006, new_rating: 1520, new_full: false)
        save_player(@t1, icu_id: 2007, new_rating: 1500, new_full: false)
        save_player(@t1, icu_id: 2008, new_rating: 1000, new_full: false)
        save_player(@t1, icu_id: 2009, new_rating: 1505, new_full: false)
        # 2003 has no rating from any source. 2004 has no rating now, but already has one on this list.

        # Ratings already on this list (from an earlier publication).
        [[2004, 1600], [2005, 1500], [2006, 1500], [2007, 1500], [2008, 1500], [2009, 1500]].each do |id, r|
          IcuRating.create!(list: @list.date, icu_id: id, rating: r, full: false, original_rating: r, original_full: false)
        end
        earlier_publication!
        @result = @list.publish(@today)
        # Publication's default scope orders by created_at (one-second resolution), so order by id.
        @pub = @list.publications.reorder(:id).last
      end

      it "publishes successfully" do
        expect(@result).to be false
        expect(@list.publications.count).to eq(2)
      end

      it "creates, keeps, updates and deletes the right members" do
        expect(IcuRating.where(list: @list.date).pluck(:icu_id)).to match_array([2001, 2002, 2006, 2007, 2008, 2009])
        expect(IcuRating.find_by(list: @list.date, icu_id: 2001).rating).to eq(400)
        expect(IcuRating.find_by(list: @list.date, icu_id: 2002).rating).to eq(1800)
        expect(IcuRating.find_by(list: @list.date, icu_id: 2002).full).to be true
        expect(IcuRating.find_by(list: @list.date, icu_id: 2006).rating).to eq(1520)
        expect(IcuRating.find_by(list: @list.date, icu_id: 2009).rating).to eq(1505)
      end

      it "resets the original ratings for the list's own month" do
        IcuRating.where(list: @list.date).each do |r|
          expect(r.original_rating).to eq(r.rating)
          expect(r.original_full).to eq(r.full)
        end
      end

      it "records the statistics" do
        expect(@pub.total).to eq(6)
        expect(@pub.creates).to eq(2)
        expect(@pub.remains).to eq(1)
        expect(@pub.updates).to eq(3)
        expect(@pub.deletes).to eq(2)
      end

      it "writes the report, with the examples in each group" do
        report = @pub.report
        expect(report).to include("tournament ratings used: 5")
        expect(report).to include("legacy ratings used: 1")
        expect(report).to include("subscribed members with no rating: 1 (2003)")
        expect(report).to include("created: 2 (2001, 2002)")
        expect(report).to include("unchanged: 1 (2007)")
        expect(report).to include("changed: 3 (2006, 2008, 2009)")
        expect(report).to include("deleted (no rating): 1 (2004)")
        expect(report).to include("deleted (no subscription): 1 (2005)")
        expect(report).to include("total: 6")
      end

      it "groups the changes by size and direction" do
        expect(@pub.report).to include("Change statistics")
        expect(@pub.report).to include("decrease > 100: 1 (2008)")
        expect(@pub.report).to include("increase of 1-10: 1 (2009)")
        expect(@pub.report).to include("increase of 11-20: 1 (2006)")
      end

      it "recalculates live ratings when publishing the last list" do
        expect(@pub.report).to match(/Starting live rating recalculation/)
        expect(@pub.report).to match(/recalculated \d+ live ratings/)
      end
    end

    context "when the list already has ratings and this is the first publication" do
      it "uses them unchanged as the first publication" do
        subscribe(2001)
        IcuRating.create!(list: @list.date, icu_id: 2001, rating: 1700, full: true)
        IcuRating.create!(list: @list.date, icu_id: 2002, rating: 1600, full: false)

        expect(@list.publish(@today)).to be false

        expect(IcuRating.where(list: @list.date).count).to eq(2)
        expect(IcuRating.find_by(list: @list.date, icu_id: 2001).rating).to eq(1700)
        pub = @list.publications.reorder(:id).last
        expect(pub.total).to eq(2)
        expect(pub.remains).to eq(2)
        expect(pub.creates).to eq(0)
        expect(pub.updates).to eq(0)
        expect(pub.report).to include("Detected pre-loaded ratings")
        expect(pub.report).to include("these will be used (unchanged) as the first publication")
      end
    end

    context "when there are no subscriptions" do
      it "returns the error message and publishes nothing" do
        result = @list.publish(@today)
        expect(result).to eq("no subscriptions found")
        expect(@list.publications.count).to eq(0)
      end
    end
  end
end
