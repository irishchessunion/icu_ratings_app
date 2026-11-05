require 'rails_helper'

# Initialisation checks for RatingRun (run in the before_create callback, so a bad
# request is saved with status "error" and an explanation in its report).
describe RatingRun do
  before(:each) do
    File.unlink(RatingRun.flag) if File.exist?(RatingRun.flag)
    @user = FactoryBot.create(:user, role: "officer")
    @t1 = Tournament.new(original_name: "Queued 1", name: "Queued 1", start: "2024-02-08", finish: "2024-02-10", rorder: 1, rounds: 6, user_id: @user.id, stage: "queued")
    @t1.save!
    @t2 = Tournament.new(original_name: "Queued 2", name: "Queued 2", start: "2024-05-04", finish: "2024-05-06", rorder: 2, rounds: 6, user_id: @user.id, stage: "queued")
    @t2.save!
  end

  after(:each) do
    File.unlink(RatingRun.flag) if File.exist?(RatingRun.flag)
  end

  def new_run(attrs)
    RatingRun.create!({ user_id: @user.id, start_tournament_id: @t1.id }.merge(attrs))
  end

  context "a valid request" do
    it "is waiting, with the last tournament and the tournament details filled in" do
      run = new_run({})
      expect(run.status).to eq("waiting")
      expect(run.last_tournament_id).to eq(@t2.id)
      expect(run.start_tournament_rorder).to eq(1)
      expect(run.last_tournament_rorder).to eq(2)
      expect(run.report).to include("Initialised")
    end

    it "throws the flag for the background process" do
      new_run({})
      expect(File.exist?(RatingRun.flag)).to be true
    end
  end

  context "an invalid request" do
    # Saved without validation, because belongs_to is not required for this model.
    def invalid_run(attrs)
      run = RatingRun.new({ user_id: @user.id, start_tournament_id: @t1.id }.merge(attrs))
      run.save(validate: false)
      run.reload
    end

    it "fails with no start tournament" do
      run = invalid_run(start_tournament_id: nil)
      expect(run.status).to eq("error")
      expect(run.report).to include("Initialisation error: no start tournament ID")
    end

    it "fails when the start tournament doesn't exist" do
      run = invalid_run(start_tournament_id: 987654)
      expect(run.status).to eq("error")
      expect(run.report).to include("couldn't find tournament with ID 987654")
    end

    it "fails when the start tournament isn't the next one to rate" do
      run = invalid_run(start_tournament_id: @t2.id)
      expect(run.status).to eq("error")
      expect(run.report).to include("the start tournament is not the next for rating")
    end

    it "fails when the last tournament doesn't come after the start" do
      @t2.destroy
      run = invalid_run(start_tournament_id: @t1.id)
      expect(run.status).to eq("error")
      expect(run.report).to include("the last tournament doesn't come after the start")
    end

    it "fails with no user" do
      run = invalid_run(user_id: nil)
      expect(run.status).to eq("error")
      expect(run.report).to include("no user ID")
    end
  end
end
