require 'rails_helper'

describe Player do
  context "#changed_from_original?" do
    before(:each) do
      @p = Player.new(
        first_name:  "Mark",
        last_name:   "Orr",
        icu_id:      1350,
        fide_id:     2500035,
        fed:         'IRL',
        title:       "IM",
        gender:      "M",
        dob:         "1955-11-09",
        icu_rating:  2192,
        fide_rating: 2264,
      )
      @p.num = 1
      @p.original_name = @p.name
      %w[icu_id fide_id fed title gender dob icu_rating fide_rating].each { |key| @p.send("original_#{key}=", @p.send(key)) }
      @p.save!
    end

    it "should not have changed" do
      expect(@p.changed_from_original?).to be false
    end

    it "should be sensitive to a change in name" do
      @p.last_name = "Fischer"
      expect(@p.changed_from_original?).to be true
      expect(@p.changed_from_original?(only: :name)).to be true
      expect(@p.changed_from_original?(only: "name")).to be true
      expect(@p.changed_from_original?(except: :name)).to be false
      expect(@p.changed_from_original?(except: "name")).to be false
      expect(@p.changed_from_original?(only: [:icu_id, :fide_rating])).to be false
      expect(@p.changed_from_original?(only: [:name, :fide_rating])).to be true
      expect(@p.changed_from_original?(only: %w[name dob])).to be true
      expect(@p.changed_from_original?(except: [:icu_id, :fide_rating])).to be true
      expect(@p.changed_from_original?(except: [:name, :fide_rating])).to be false
      expect(@p.changed_from_original?(except: %w[name fed])).to be false
    end

    it "should not be sensitive to a reversal of the original name" do
      @p.original_name = "Mark Orr"
      expect(@p.changed_from_original?).to be false
    end
  end

  context "#signature" do
    before(:each) do
      f = "bunratty_masters_2011.tab"
      load_icu_players_for(f)
      @t = test_tournament(f, 1)
    end

    it "should get right signature for foreign player who played in every round" do
      p = @t.players.find_by_last_name_and_first_name("Short", "Nigel")
      expect(p.signature).to eq("2658 1W19 2D11 3W8 4L1 5D9 6W14")
    end

    it "should get right signature for ICU player who didn't play in every round" do
      p = @t.players.find_by_last_name("Cafolla")
      expect(p.signature).to eq("159 1L11 2D19 3W27 4W25 5L7")
    end

    it "should get right signature for new player who didn't play in any rounds" do
      p = @t.players.find_by_last_name("Grennel")
      expect(p.signature).to eq("")
    end
  end

  context "#update" do
    before(:each) do
      @p = Player.new(
        first_name:  "Mark",
        last_name:   "Orr",
        icu_id:      1350,
        fide_id:     2500035,
        fed:         'IRL',
        title:       "IM",
        gender:      "M",
        dob:         "1955-11-09",
        icu_rating:  2192,
        fide_rating: 2264,
      )
      @p.num = 1
      @p.original_name = @p.name
      %w[icu_id fide_id fed title gender dob icu_rating fide_rating].each { |key| @p.send("original_#{key}=", @p.send(key)) }
      @p.save!
    end

    it "dob should be a date" do
      expect(@p.dob).to eq Date.new(1955, 11, 9)
    end

    it "dob should be a date after updating" do
      @p.update_column(:dob, "1955-05-09")
      expect(@p.dob).to eq Date.new(1955, 5, 9)
    end

  end

  context "#get_last_ratings" do
    before(:each) do
      @david = IcuPlayer.new(
        id: 4941,
        first_name: "David",
        last_name: "Murray",
        deceased: false
      )
      @david.save!
      @john = IcuPlayer.new(
        id: 795,
        first_name: "John",
        last_name: "Loughran",
        deceased: false
      )
      @john.save!

      @bunratty = Tournament.new(
        original_name: "Bunratty",
        name: "Bunratty",
        start: "2024-02-08",
        finish: "2024-02-10",
        rorder: 1,
        rounds: 6,
        user_id: 100,
        stage: "rated")
      @bunratty.save!

      @malahide = Tournament.new(
        original_name: "Malahide",
        name: "Malahide",
        start: "2024-05-04",
        finish: "2024-05-06",
        rorder: 2,
        rounds: 6,
        user_id: 100,
        stage: "rated")
      @malahide.save!

      @david_bunratty = Player.new(
        first_name:  "David",
        last_name:   "Murray",
        original_name: "Murray, David",
        icu_id:      4941,
        new_rating:  2100,
        num: 5,
        tournament_id: @bunratty.id
      )
      @david_bunratty.save!
      @david_malahide = @david_bunratty.dup
      @david_malahide.tournament_id = @malahide.id
      @david_malahide.new_rating = 2080
      @david_malahide.save!

      @john_bunratty = Player.new(
        first_name: "John",
        last_name: "Loughran",
        original_name: "Loughran, John",
        icu_id: @john.id,
        new_rating: 1400,
        num: 6,
        tournament_id: @bunratty.id
      )
      @john_bunratty.save!

      @david_rating = IcuRating.new(
        list: Date.new(2024, 3, 1),
        icu_id: @david.id,
        rating: 2100 # post-adjustment, though 2100 means no adjustment
      )

      @john_rating = IcuRating.new(
        list: Date.new(2024, 3, 1),
        icu_id: @john.id,
        rating: 1760 # post-adjustment rating
      )
      @john_rating.save!
    end

    it "before the adjustment, should get a player's rating" do
      players = Player.get_last_ratings([795, 4941], max_rorder: 1, max_date: Date.new(2024, 2, 29))
      expect(players[4941].new_rating).to eq(2100)
      expect(players[795].new_rating).to eq(1400)
    end

    it "after the adjustment, by rorder, should get a player's rating" do
      players = Player.get_last_ratings([795, 4941], max_rorder: 2)
      expect(players[4941].new_rating).to eq(2080)
      expect(players[795].new_rating).to eq(1760)
    end

    it "after the adjustment, by date, should get a player's rating" do
      players = Player.get_last_ratings([795, 4941], max_rorder: 1, max_date: Date.new(2024, 4, 5))
      expect(players[4941].new_rating).to eq(2100)
      expect(players[795].new_rating).to eq(1760)
    end
  end



end
