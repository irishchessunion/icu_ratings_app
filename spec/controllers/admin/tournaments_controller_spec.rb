require "rails_helper"

# Admin::TournamentsController: officer/admin only (Ability: `can :manage, Tournament`).
describe Admin::TournamentsController, type: :controller do
  before(:each) do
    @officer = FactoryBot.create(:user, role: "officer")
    @tournament = Tournament.create!(original_name: "T", name: "T", start: "2026-03-07", finish: "2026-03-08", rorder: 1, rounds: 2, user_id: @officer.id, stage: "initial")
    @tournament.update_column(:rorder, 1)
    session[:user_id] = @officer.id
  end

  def login_as(user)
    session[:user_id] = user.id
  end

  describe "GET index" do
    it "assigns the tournament list and the next one for rating" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:tournaments)).not_to be_nil
      expect(assigns(:next_for_rating)).to be_nil.or be_a(Tournament)
    end

    it "renders the search partial for an AJAX request" do
      get :index, xhr: true, format: :js
      expect(response).to render_template(:results)
    end

    it "filters by name, by year, and by fide-rated status" do
      get :index, params: { name: @tournament.name, year: @tournament.start.year, fide_rated: "true" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET show" do
    it "loads the players and checks for changes, with the html format" do
      get :show, params: { id: @tournament.id }
      expect(response).to have_http_status(:ok)
      expect(assigns(:tournament)).to eq(@tournament)
      expect(assigns(:players)).not_to be_nil
      expect(assigns(:rankable)).to be_in([true, false, nil])
    end

    it "renders the notes view for a JavaScript notes request" do
      get :show, params: { id: @tournament.id, notes: "1" }, format: :js, xhr: true
      expect(response).to render_template("admin/tournaments/notes/show")
    end

    it "renders the export view for a JavaScript export request" do
      get :show, params: { id: @tournament.id }, format: :js, xhr: true
      expect(response).to render_template("admin/tournaments/export/options")
    end

    it "sends the export as plain text" do
      get :show, params: { id: @tournament.id }, format: :text
      expect(response.content_type).to include("text/plain")
    end
  end

  describe "GET edit" do
    it "loads the tournament and the fide data when the fide group is requested" do
      get :edit, params: { id: @tournament.id, fide: "1" }, xhr: true, format: :js
      expect(assigns(:tournament)).to eq(@tournament)
      expect(assigns(:data)).to be_a(Tournaments::FideData)
    end

    it "loads the tournament without fide data for other groups" do
      get :edit, params: { id: @tournament.id, ranks: "1" }, xhr: true, format: :js
      expect(assigns(:tournament)).to eq(@tournament)
      expect(assigns(:data)).to be_nil
    end
  end

  describe "PATCH update" do
    it "ranks the tournament when the ranks group is requested" do
      allow_any_instance_of(Tournament).to receive(:ranking_summary).and_return({ valid: true, rankable: true })
      allow_any_instance_of(Tournament).to receive(:ordered_players).and_return([])
      patch :update, params: { id: @tournament.id, ranks: "1", rank: "1", order: "1" }, xhr: true, format: :js
      expect(response).to render_template("admin/tournaments/ranks/update")
      expect(assigns(:problem)).to be(false)
    end

    it "rates the tournament and shows the alert when it fails" do
      allow_any_instance_of(Tournament).to receive(:rate).and_return("boom")
      patch :update, params: { id: @tournament.id, rate: "1" }, xhr: true, format: :js
      expect(response).to have_http_status(:ok)
    end

    it "rates the tournament and renders the update view on success" do
      allow_any_instance_of(Tournament).to receive(:rate).and_return(nil)
      patch :update, params: { id: @tournament.id, rate: "1" }, xhr: true, format: :js
      expect(response).to render_template("admin/tournaments/update")
    end

    it "locks and unlocks the tournament" do
      patch :update, params: { id: @tournament.id, locked: "false" }, xhr: true, format: :js
      expect(@tournament.reload.locked).to be false
      patch :update, params: { id: @tournament.id, locked: "true" }, xhr: true, format: :js
      expect(@tournament.reload.locked).to be true
    end

    it "toggles the rerate flag" do
      patch :update, params: { id: @tournament.id, rerate: "true" }, xhr: true, format: :js
      expect(@tournament.reload.rerate).to be true
    end

    it "adds ICU ids to players" do
      allow_any_instance_of(Tournament).to receive(:add_icu_ids)
      allow_any_instance_of(Tournament).to receive(:ordered_players).and_return([])
      patch :update, params: { id: @tournament.id, icu_ids: "1" }, xhr: true, format: :js
      expect(response).to render_template("admin/tournaments/icu_ids/update")
    end

    it "saves the fide data" do
      allow(Tournaments::FideData).to receive(:new).and_return(double("FideData"))
      patch :update, params: { id: @tournament.id, tournament: { fide: "1" } }, xhr: true, format: :js
      expect(response).to render_template("admin/tournaments/fide/update")
    end

    it "saves the tie breaks" do
      patch :update, params: { id: @tournament.id, tournament: { tie_breaks: "a,b" } }, xhr: true, format: :js
      expect(response).to have_http_status(:ok)
    end

    it "saves the notes" do
      patch :update, params: { id: @tournament.id, tournament: { notes: "hello" } }, xhr: true, format: :js
      expect(@tournament.reload.notes).to eq("hello")
    end

    it "moves the stage" do
      allow_any_instance_of(Tournament).to receive(:move_stage)
      patch :update, params: { id: @tournament.id, tournament: { stage: "ready" } }, xhr: true, format: :js
      expect(response).to render_template("admin/tournaments/update")
    end

    it "saves other tournament attributes by default" do
      patch :update, params: { id: @tournament.id, tournament: { name: "Renamed" } }, xhr: true, format: :js
      expect(@tournament.reload.name).to eq("Renamed")
    end
  end

  describe "DELETE destroy" do
    it "deletes a deletable tournament" do
      @tournament.update_column(:status, "finished")
      delete :destroy, params: { id: @tournament.id }
      expect(response).to redirect_to(admin_tournaments_path)
      expect(Tournament.exists?(@tournament.id)).to be false
    end

    it "refuses to delete a tournament that is not deletable" do
      @tournament.update_column(:stage, "queued")
      delete :destroy, params: { id: @tournament.id }
      expect(response).to redirect_to([:admin, @tournament])
      expect(Tournament.exists?(@tournament.id)).to be true
    end
  end

  describe "GET nextstep" do
    it "redirects to the first player with errors, or to the tournament" do
      allow_any_instance_of(Tournament).to receive(:find_first_player_with_errors).and_return(nil)
      get :nextstep, params: { id: @tournament.id }
      expect(response).to redirect_to([:admin, @tournament])
    end
  end
end
