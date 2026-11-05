require 'rails_helper'

# Result: the score helpers, and Result#update_results, which edits a game and mirrors
# the change onto the opponent's record for the same round. Expected values are worked
# out by hand from the rules in app/models/result.rb.
describe Result do
  describe "score and opposite helpers" do
    it "scores a win 1, a draw 0.5 and a loss 0" do
      expect(Result.new(result: "W").score).to eq(1.0)
      expect(Result.new(result: "D").score).to eq(0.5)
      expect(Result.new(result: "L").score).to eq(0.0)
    end

    it "gives the opposite result: W and L swap, D stays D" do
      expect(Result.new(result: "W").opposite_result).to eq("L")
      expect(Result.new(result: "L").opposite_result).to eq("W")
      expect(Result.new(result: "D").opposite_result).to eq("D")
    end

    it "gives the opposite colour: W and B swap, anything else is nil" do
      expect(Result.new(colour: "W").opposite_colour).to eq("B")
      expect(Result.new(colour: "B").opposite_colour).to eq("W")
      expect(Result.new(colour: nil).opposite_colour).to be_nil
    end

    it "builds a signature from round, result and opponent" do
      expect(Result.new(round: 3, result: "W", opponent_id: 42).signature).to eq("3W42")
    end
  end

  describe "#update_results" do
    before(:each) do
      @tournament = Tournament.create!(original_name: "Upd", name: "Upd", start: "2026-09-18", finish: "2026-09-20", rorder: 1, rounds: 6, user_id: 100, stage: "ready")
      @a = make_player("Ann", 1)
      @b = make_player("Ben", 2)
      @c = make_player("Cat", 3)
      # Round 1: Ann (white) beat Ben (black). Each side has a record.
      @ra = Result.create!(player: @a, opponent: @b, round: 1, result: "W", colour: "W", rateable: true)
      @rb = Result.create!(player: @b, opponent: @a, round: 1, result: "L", colour: "B", rateable: true)
    end

    def make_player(first, num)
      p = Player.new(first_name: first, last_name: "Test", original_name: "Test, #{first}", category: "icu_player", num: num, bonus: 0, tournament_id: @tournament.id)
      p.save!(validate: false)
      p
    end

    def attrs(overrides = {})
      { round: 1, player_id: @a.id, opponent_id: @b.id, result: "W", colour: "W", rateable: "true" }.merge(overrides)
    end

    it "mirrors a rateable change onto the opponent with the opposite result and colour" do
      # Ann's win becomes a draw, so Ben's loss becomes a draw too.
      expect(@ra.update_results(attrs(result: "D"), "D")).to be true
      @rb.reload
      expect(@ra.reload.result).to eq("D")
      expect(@rb.result).to eq("D")
      expect(@rb.colour).to eq("B")
      expect(@rb.rateable).to be true
      expect(@rb.opponent_id).to eq(@a.id)
    end

    it "reverses a win into a loss for the opponent" do
      @ra.update_results(attrs(result: "L", colour: "B"), "W")
      expect(@rb.reload.result).to eq("W")
      expect(@rb.colour).to eq("W")
    end

    it "keeps the opponent's result for an unrateable game, and marks both sides unrateable" do
      # The opponent already has a result in the round, so that result is kept as it is.
      @ra.update_results(attrs(rateable: "false", result: "W"), "L")
      @rb.reload
      expect(@ra.reload.rateable).to be false
      expect(@rb.result).to eq("L")
      expect(@rb.rateable).to be false
    end

    it "creates the opponent's record when there isn't one for the round" do
      # Cat has no result in round 1, so Ann's game against her creates one.
      expect(@ra.update_results(attrs(opponent_id: @c.id, result: "W"), "L")).to be true
      mirror = @c.result_in_round(1)
      expect(mirror).not_to be_nil
      expect(mirror.result).to eq("L")
      expect(mirror.colour).to eq("B")
      expect(mirror.rateable).to be true
      expect(mirror.opponent_id).to eq(@a.id)
    end

    it "clears the old opponent's link when the opponent changes" do
      # Ann's round 1 opponent changes from Ben to Cat. Ben's record is unlinked and not rateable.
      @ra.update_results(attrs(opponent_id: @c.id, result: "W"), "L")
      @rb.reload
      expect(@rb.rateable).to be false
      expect(@rb.opponent_id).to be_nil
      expect(@rb.result).to eq("L")
      expect(@c.result_in_round(1).opponent_id).to eq(@a.id)
    end

    it "treats an opponent of 0 (none) as no opponent: unrateable, and Ben is unlinked" do
      expect(@ra.update_results(attrs(opponent_id: "0", rateable: "true"), "L")).to be true
      @ra.reload
      @rb.reload
      expect(@ra.opponent_id).to be_nil
      expect(@ra.rateable).to be false
      expect(@rb.opponent_id).to be_nil
      expect(@rb.rateable).to be false
    end

    it "returns false and changes nothing for an invalid result" do
      expect(@ra.update_results(attrs(result: "X"), "L")).to be false
      expect(@ra.reload.result).to eq("W")
      expect(@rb.reload.result).to eq("L")
    end

    it "reads rateable from the form's string value: \"false\" makes the game unrateable" do
      # Form parameters are strings. update_results compares rateable with the string "true",
      # so only that exact value makes a game rateable. A boolean is not what the form sends.
      @ra.update_results(attrs(rateable: "false"), "L")
      expect(@ra.reload.rateable).to be false
    end
  end
end
