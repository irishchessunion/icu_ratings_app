require "rails_helper"

# Admin::ResultsController. Permissions come from Ability:
#   - officers: manage Result (so any unlocked tournament), and cannot modify locked tournaments
#   - admins:   manage everything, but cannot modify locked tournaments
#   - reporters: can read results, and can modify results in their own unlocked tournaments
#   - members:  no access
describe Admin::ResultsController, type: :controller do
  render_views

  before(:each) do
    @officer = FactoryBot.create(:user, role: "officer")
    @admin = FactoryBot.create(:user, role: "admin")
    @owner = FactoryBot.create(:user, role: "reporter")
    @other_reporter = FactoryBot.create(:user, role: "reporter")
    @member = FactoryBot.create(:user, role: "member")

    @tournament = Tournament.create!(original_name: "Results T", name: "Results T", start: "2026-09-18", finish: "2026-09-20", rorder: 1, rounds: 6, user_id: @owner.id, stage: "ready")
    @p1 = make_player("Ann", 1)
    @p2 = make_player("Ben", 2)
    @p3 = make_player("Cat", 3)

    # Round 1: Ann (p1) beat Ben (p2). The mirror record on Ben is a loss.
    @r1 = Result.create!(player: @p1, opponent: @p2, round: 1, result: "W", colour: "W", rateable: true)
    @r2 = Result.create!(player: @p2, opponent: @p1, round: 1, result: "L", colour: "B", rateable: true)
  end

  def make_player(first, num)
    p = Player.new(first_name: first, last_name: "Test", original_name: "Test, #{first}", category: "icu_player", num: num, bonus: 0, tournament_id: @tournament.id)
    p.save!(validate: false)
    p
  end

  def login_as(user)
    session[:user_id] = user.id
  end

  def result_params(overrides = {})
    { round: 1, player_id: @p1.id, opponent_id: @p2.id, result: "W", colour: "W", rateable: "true" }.merge(overrides)
  end

  describe "GET new" do
    # Current Ability: reporters can edit results in their own tournament, but have no permission to
    # add them (new or create), so the owner is refused here. Flagged for the owner in PLAN.md.
    it "is denied to the tournament's reporter, who can edit results but not add them" do
      login_as(@owner)
      get :new, params: { player_id: @p1.id, round: 2 }, xhr: true, format: :js
      expect(response.body).to include("Not authorized")
    end

    it "builds a result for the round, with the possible opponents, for an officer" do
      login_as(@officer)
      get :new, params: { player_id: @p1.id, round: 2 }, xhr: true, format: :js
      expect(assigns(:result).round).to eq(2)
      expect(assigns(:player)).to eq(@p1)
      # The form is returned inside a JavaScript string, so its quotes are escaped (\"), and the
      # closing tags are escaped too (<\/option>). Ann (p1) is not offered as her own opponent.
      expect(response.body).to include("Test, Ben<\\/option>")
      expect(response.body).to include("Test, Cat<\\/option>")
      expect(response.body).not_to include("Test, Ann<\\/option>")
    end

    it "is allowed to an officer on an unlocked tournament" do
      login_as(@officer)
      get :new, params: { player_id: @p1.id, round: 2 }, xhr: true, format: :js
      expect(response).to have_http_status(:ok)
    end

    it "is denied to a member" do
      login_as(@member)
      get :new, params: { player_id: @p1.id, round: 2 }, xhr: true, format: :js
      expect(response.body).to include("Not authorized")
    end

    # KNOWN ISSUE (PLAN.md): an admin can open the new-result form on a locked tournament.
    # AGENTS.md says locked tournaments restrict edits even for admins. No example here, so
    # the suite doesn't encode the current behaviour. Decide first, then add the example.
  end

  describe "POST create" do
    it "saves a new result and renders the success branch of update.js" do
      login_as(@officer)
      expect {
        post :create, params: { result: result_params(round: 2, opponent_id: @p3.id) }, xhr: true, format: :js
      }.to change(Result, :count).by(1)
      expect(assigns(:player)).to eq(@p1)
      expect(response.body).to include("#score")
    end

    it "does not save an invalid result, and renders the error branch" do
      login_as(@officer)
      expect {
        post :create, params: { result: result_params(round: 2, result: "X") }, xhr: true, format: :js
      }.not_to change(Result, :count)
      expect(assigns(:player)).to be_nil
      expect(response.body).to include("Error updating result")
    end

    # Current Ability: reporters have no create permission on Result, even in their own
    # tournament, although the new-result form is available to them. Flagged for the owner.
    it "is denied to the tournament's reporter (current Ability has no create for reporters)" do
      login_as(@owner)
      expect {
        post :create, params: { result: result_params(round: 2) }, xhr: true, format: :js
      }.not_to change(Result, :count)
      expect(response.body).to include("Not authorized")
    end
  end

  describe "GET edit" do
    it "assigns the result's player, tournament and opponents" do
      login_as(@owner)
      get :edit, params: { id: @r1.id }, xhr: true, format: :js
      expect(assigns(:player)).to eq(@p1)
      expect(assigns(:tournament)).to eq(@tournament)
      # @opponents is the select list: [label, id] pairs, with a blank "None" first.
      expect(assigns(:opponents)).to include(["Test, Ben", @p2.id.to_s], ["Test, Cat", @p3.id.to_s])
    end

    it "is denied to a member" do
      login_as(@member)
      get :edit, params: { id: @r1.id }, xhr: true, format: :js
      expect(response.body).to include("Not authorized")
    end
  end

  describe "PATCH update" do
    it "updates the result and its mirror, and renders the success branch" do
      login_as(@owner)
      patch :update, params: { id: @r1.id, result: result_params(result: "D", colour: "W"), opp_result: "D" }, xhr: true, format: :js
      expect(@r1.reload.result).to eq("D")
      expect(@r2.reload.result).to eq("D")
      expect(assigns(:player)).to eq(@p1)
      expect(response.body).to include("dialog_update_player")
    end

    it "renders the error branch when the update is refused" do
      login_as(@owner)
      allow_any_instance_of(Result).to receive(:update_results).and_return(false)
      patch :update, params: { id: @r1.id, result: result_params(result: "D"), opp_result: "D" }, xhr: true, format: :js
      expect(assigns(:player)).to be_nil
      expect(response.body).to include("Error updating result")
    end

    it "only permits the listed attributes" do
      login_as(@owner)
      patch :update, params: { id: @r1.id, result: result_params(tournament_id: 999999, result: "W"), opp_result: "L" }, xhr: true, format: :js
      expect(@r1.reload.player_id).to eq(@p1.id)
    end

    it "is denied on a locked tournament, even to an admin" do
      @tournament.update_column(:locked, true)
      login_as(@admin)
      patch :update, params: { id: @r1.id, result: result_params(result: "D"), opp_result: "D" }, xhr: true, format: :js
      expect(@r1.reload.result).to eq("W")
      expect(response.body).to include("Not authorized")
    end

    it "is denied to a reporter who doesn't own the tournament" do
      login_as(@other_reporter)
      patch :update, params: { id: @r1.id, result: result_params(result: "D"), opp_result: "D" }, xhr: true, format: :js
      expect(@r1.reload.result).to eq("W")
    end
  end
end
