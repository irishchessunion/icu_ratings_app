require 'rails_helper'

# TournamentsController: the public tournament pages, and the form that creates a tournament
# from a single ICU player's entry (with their results). Creating needs `can :create, Tournament`
# (reporters, officers and admins); viewing is public.
describe TournamentsController, type: :controller do
  before(:each) do
    @reporter = FactoryBot.create(:user, role: "reporter")
    @member = FactoryBot.create(:user, role: "member")
    @icu = FactoryBot.create(:icu_player, first_name: "Ann", last_name: "Adams", fed: "IRL", title: nil, gender: "F")
  end

  def form_params(overrides = {})
    {
      name: "Spring Open", start_date: "2026-03-07", end_date: "2026-03-08", num_rounds: "2", icu_id: @icu.id,
      r1_last_name: "Brown", r1_first_name: "Ben", r1_fed: "IRL", r1_fide_title: "", r1_fide_elo: "2100",
      r1_result: "Win", r1_colour: "White",
      r2_last_name: "Clarke", r2_first_name: "Cat", r2_fed: "ENG", r2_fide_title: "FM", r2_fide_elo: "2200",
      r2_result: "Draw", r2_colour: "Black"
    }.merge(overrides)
  end

  describe "GET new" do
    it "is allowed to a reporter" do
      session[:user_id] = @reporter.id
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "is denied to a member" do
      session[:user_id] = @member.id
      get :new
      expect(response).to redirect_to(log_in_path)
    end
  end

  describe "POST create" do
    before(:each) { session[:user_id] = @reporter.id }

    it "creates the tournament, the ICU player's entry, and both rounds' results" do
      expect { post :create, params: form_params }.to change(Tournament, :count).by(1)
      tournament = Tournament.last
      expect(response).to redirect_to(admin_tournament_path(tournament))
      expect(tournament.name).to eq("Spring Open")
      expect(tournament.rounds).to eq(2)
      expect(tournament.user_id).to eq(@reporter.id)

      entry = tournament.players.find_by(icu_id: @icu.id)
      expect(entry.num).to eq(1)
      expect(entry.original_name).to eq(@icu.name)
    end

    it "records each opponent, with the opposite result and colour for the opponent" do
      post :create, params: form_params
      tournament = Tournament.last
      entry = tournament.players.find_by(icu_id: @icu.id)

      r1 = entry.result_in_round(1)
      expect([r1.result, r1.colour, r1.rateable]).to eq(["W", "W", true])
      expect(r1.opponent.original_name).to eq("Brown, Ben")
      expect(r1.opponent.num).to eq(2)
      mirror1 = r1.opponent.result_in_round(1)
      expect([mirror1.result, mirror1.colour]).to eq(["L", "B"])

      r2 = entry.result_in_round(2)
      expect([r2.result, r2.colour]).to eq(["D", "B"])
      expect(r2.opponent.fide_rating).to eq(2200)
      expect(r2.opponent.title).to eq("FM")
      expect(r2.opponent.num).to eq(3)
    end

    it "is denied to a member" do
      session[:user_id] = @member.id
      expect { post :create, params: form_params }.not_to change(Tournament, :count)
      expect(response).to redirect_to(log_in_path)
    end

    it "raises RecordNotFound for an unknown ICU player" do
      expect { post :create, params: form_params(icu_id: 987654) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET index" do
    it "lists tournaments for a normal request" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:tournaments)).not_to be_nil
    end

    it "renders the results partial for an AJAX request" do
      get :index, xhr: true, format: :js
      expect(response).to render_template(:results)
    end
  end

  describe "GET show" do
    before(:each) do
      @tournament = Tournament.create!(original_name: "Show", name: "Show", start: "2026-03-07", finish: "2026-03-08", rorder: 1, rounds: 2, user_id: @reporter.id, stage: "rated")
    end

    it "shows the tournament's players in HTML" do
      get :show, params: { id: @tournament.id }
      expect(response).to render_template(:show)
      expect(assigns(:tournament)).to eq(@tournament)
      expect(assigns(:players)).not_to be_nil
      expect(assigns(:rankable)).to be_in([true, false])
    end

    it "shows the notes for a JavaScript request" do
      get :show, params: { id: @tournament.id }, format: :js, xhr: true
      expect(response).to render_template(:show_notes)
      expect(assigns(:tournament)).to eq(@tournament)
    end
  end
end
