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

  context "#signature", truncation: true do
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

  # Unsaved players and results are enough for these calculations: they only use the
  # in-memory results association and each opponent's start rating.
  context "rating calculation helpers" do
    def make_player(attrs = {})
      Player.new({ category: "icu_player", bonus: 0, num: 1, status: "active", original_name: "x", last_name: "x" }.merge(attrs))
    end

    def make_result(player, opponent, result, rateable: true, round: 1)
      player.results.build(round: round, result: result, opponent: opponent, rateable: rateable, colour: "W")
    end

    context "#start_rating" do
      it "uses the old rating for a full-rated ICU player with no bonus" do
        p = make_player(old_rating: 2000, old_games: 40, old_full: true, new_rating: 2050)
        expect(p.start_rating).to eq(2000)
      end

      it "uses the new rating when a full-rated ICU player has a bonus" do
        p = make_player(old_rating: 2000, old_games: 40, old_full: true, new_rating: 2050, bonus: 10)
        expect(p.start_rating).to eq(2050)
      end

      it "uses the new rating for a provisional ICU player" do
        p = make_player(old_rating: 1900, old_games: 5, old_full: false, new_rating: 1950)
        expect(p.start_rating).to eq(1950)
      end

      it "uses the new rating for an ICU player in their first tournament" do
        p = make_player(old_rating: nil, old_games: nil, old_full: nil, new_rating: 1200)
        expect(p.start_rating).to eq(1200)
      end

      it "uses the new rating for a foreign player, even with an old rating" do
        p = make_player(category: "foreign_player", old_rating: 2000, old_games: 40, old_full: true, new_rating: 2100)
        expect(p.start_rating).to eq(2100)
      end
    end

    context "#rateable_games and #rateable_score" do
      before(:each) do
        @me = make_player(new_rating: 1900)
        @a  = make_player(new_rating: 2000)
        @b  = make_player(new_rating: 1800)
        make_result(@me, @a, "W", round: 1)
        make_result(@me, @b, "D", round: 2)
        make_result(@me, @a, "L", round: 3, rateable: false)
        make_result(@me, nil, "W", round: 4, rateable: false) # bye
      end

      it "counts only rateable games" do
        expect(@me.rateable_games).to eq(2)
      end

      it "sums the score of rateable games only" do
        expect(@me.rateable_score).to eq(1.5)
      end

      it "counts a bye as neither rateable nor scored" do
        expect(@me.opponents).to eq(3)
      end
    end

    context "#ave_opp_rating" do
      it "averages the start ratings of rateable opponents" do
        me = make_player(new_rating: 1900)
        make_result(me, make_player(new_rating: 2000), "W", round: 1)
        make_result(me, make_player(new_rating: 1800), "D", round: 2)
        make_result(me, make_player(new_rating: 1600, category: "foreign_player"), "L", round: 3)
        expect(me.ave_opp_rating).to eq(1800.0)
      end

      it "ignores unrateable opponents" do
        me = make_player(new_rating: 1900)
        make_result(me, make_player(new_rating: 2000), "W", round: 1)
        make_result(me, make_player(new_rating: 1800), "W", round: 2)
        make_result(me, make_player(new_rating: 2500), "W", round: 3, rateable: false)
        expect(me.ave_opp_rating).to eq(1900.0)
      end

      it "is zero when there are no rateable games" do
        me = make_player(new_rating: 1900)
        make_result(me, make_player(new_rating: 2000), "W", round: 1, rateable: false)
        expect(me.ave_opp_rating).to eq(0.0)
      end
    end

    context "#performance_rating" do
      it "equals the average opponent rating when the score is half the games" do
        # Average opponent 1800, score 1.5 from 3 games: 1800 + 400 * 0 / 3
        me = make_player(new_rating: 1900)
        make_result(me, make_player(new_rating: 2000), "W", round: 1)
        make_result(me, make_player(new_rating: 1800), "D", round: 2)
        make_result(me, make_player(new_rating: 1600, category: "foreign_player"), "L", round: 3)
        expect(me.performance_rating).to eq(1800.0)
      end

      it "adds 400 per game of score above half the games: 2 wins against 2000 and 1800" do
        # Average opponent 1900, score 2 from 2 games: 1900 + 400 * (4 - 2) / 2
        me = make_player(new_rating: 1900)
        make_result(me, make_player(new_rating: 2000), "W", round: 1)
        make_result(me, make_player(new_rating: 1800), "W", round: 2)
        expect(me.performance_rating).to eq(2300.0)
      end

      it "gives the average opponent rating for an even score, and 400 less for two losses" do
        # Average opponent 1900, score 1 from 2 games: 1900 + 400 * (2 - 2) / 2 = 1900
        # Two losses instead gives 1900 + 400 * (0 - 2) / 2 = 1500
        me = make_player(new_rating: 1900)
        make_result(me, make_player(new_rating: 2000), "W", round: 1)
        make_result(me, make_player(new_rating: 1800), "L", round: 2)
        expect(me.performance_rating).to eq(1900.0)

        lose = make_player(new_rating: 1900)
        make_result(lose, make_player(new_rating: 2000), "L", round: 1)
        make_result(lose, make_player(new_rating: 1800), "L", round: 2)
        expect(lose.performance_rating).to eq(1500.0)
      end

      it "ignores unrateable games, including their score" do
        me = make_player(new_rating: 1900)
        make_result(me, make_player(new_rating: 2000), "W", round: 1)
        make_result(me, make_player(new_rating: 1800), "W", round: 2)
        make_result(me, make_player(new_rating: 2500), "W", round: 3, rateable: false)
        expect(me.performance_rating).to eq(2300.0)
      end

      it "is zero when there are no rateable games" do
        me = make_player(new_rating: 1900)
        make_result(me, make_player(new_rating: 2000), "W", round: 1, rateable: false)
        expect(me.performance_rating).to eq(0.0)
      end
    end
  end

  context "#add_player (inputs to the rating calculation)" do
    before(:each) do
      @t = ICU::RatedTournament.new(desc: "Scratch")
    end

    def save_player(attrs)
      p = Player.new({ category: "icu_player", num: 1, bonus: 0, original_name: "x", last_name: "x", first_name: "x" }.merge(attrs))
      p.save!(validate: false)
      p
    end

    it "adds a full-rated ICU player with their rating and K-factor" do
      p = save_player(old_rating: 2000, old_full: true, old_games: 40, k_factor: 20)
      p.add_player(@t)
      rated = @t.player(p.id)
      expect(rated.type).to eq(:rated)
      expect(rated.rating).to eq(2000)
      expect(rated.kfactor).to eq(20)
    end

    it "adds a provisional ICU player with their rating and games" do
      p = save_player(old_rating: 1800, old_full: false, old_games: 5)
      p.add_player(@t)
      rated = @t.player(p.id)
      expect(rated.type).to eq(:provisional)
      expect(rated.rating).to eq(1800)
      expect(rated.games).to eq(5)
    end

    it "adds an ICU player in their first tournament as unrated" do
      p = save_player(old_rating: nil, old_games: nil, old_full: nil)
      p.add_player(@t)
      expect(@t.player(p.id).type).to eq(:unrated)
    end

    it "adds a new player as unrated" do
      p = save_player(category: "new_player")
      p.add_player(@t)
      expect(@t.player(p.id).type).to eq(:unrated)
    end

    it "adds a foreign player with their old rating" do
      p = save_player(category: "foreign_player", old_rating: 2100)
      p.add_player(@t)
      rated = @t.player(p.id)
      expect(rated.type).to eq(:foreign)
      expect(rated.rating).to eq(2100)
    end

    it "refuses an ICU player whose rating type can't be worked out" do
      # Old rating but not full, and no games recorded: neither full nor provisional.
      p = save_player(old_rating: 1800, old_full: false, old_games: nil)
      expect { p.add_player(@t) }.to raise_error(ICU::Error, /can't add ICU player/)
    end
  end

  context "#get_old_rating (the rating a player starts a tournament with)" do
    before(:each) do
      @p = Player.new(first_name: "A", last_name: "B", original_name: "B, A", icu_id: 4001, num: 1, bonus: 0, category: "icu_player")
      @p.save!(validate: false)
    end

    it "prefers the latest rated tournament to the legacy list" do
      latest = { 4001 => Player.new(new_rating: 1900, new_games: 12, new_full: true) }
      legacy = { 4001 => OldRating.new(icu_id: 4001, rating: 1700, games: 8, full: false) }
      @p.get_old_rating(latest, legacy)
      @p.reload
      expect([@p.old_rating, @p.old_games, @p.old_full]).to eq([1900, 12, true])
    end

    it "uses the legacy list when there's no rated tournament" do
      legacy = { 4001 => OldRating.new(icu_id: 4001, rating: 1700, games: 8, full: false) }
      @p.get_old_rating({}, legacy)
      @p.reload
      expect([@p.old_rating, @p.old_games, @p.old_full]).to eq([1700, 8, false])
    end

    it "has no old rating when there's neither" do
      @p.get_old_rating({}, {})
      @p.reload
      expect([@p.old_rating, @p.old_games, @p.old_full]).to eq([nil, 0, false])
    end

    it "refuses a player with an unknown category" do
      @p.update_column(:category, "bogus")
      @p.reload
      expect { @p.get_old_rating({}, {}) }.to raise_error(ICU::Error, /invalid category \(bogus\)/)
    end
  end

  context "#next_player and .get_last_rating" do
    before(:each) do
      @t1 = Tournament.new(original_name: "T1", name: "T1", start: "2024-02-08", finish: "2024-02-10", rorder: 1, rounds: 6, user_id: 100, stage: "rated")
      @t1.save!
      @t2 = Tournament.new(original_name: "T2", name: "T2", start: "2024-05-04", finish: "2024-05-06", rorder: 2, rounds: 6, user_id: 100, stage: "rated")
      @t2.save!
      @first = Player.new(first_name: "A", last_name: "B", original_name: "B, A", icu_id: 3001, new_rating: 1900, num: 1, tournament_id: @t1.id, category: "icu_player", bonus: 0)
      @first.save!(validate: false)
      @second = Player.new(first_name: "A", last_name: "B", original_name: "B, A", icu_id: 3001, new_rating: 1950, num: 1, tournament_id: @t2.id, category: "icu_player", bonus: 0, last_player_id: @first.id)
      @second.save!(validate: false)
    end

    it "finds the same player in their next rated tournament" do
      expect(@first.next_player).to eq(@second)
    end

    it "has no next player after the last one" do
      expect(@second.next_player).to be_nil
    end

    it "has no next player if the next tournament isn't rated yet" do
      @t2.update_column(:stage, "queued")
      expect(@first.next_player).to be_nil
    end

    it "gets a player's rating from the last tournament before a given order number" do
      expect(Player.get_last_rating(3001, 3)).to eq(@second)
      expect(Player.get_last_rating(3001, 2)).to eq(@first)
      expect(Player.get_last_rating(3001, 1)).to be_nil
    end
  end
end
