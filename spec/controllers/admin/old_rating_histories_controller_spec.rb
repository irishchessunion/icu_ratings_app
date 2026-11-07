require "rails_helper"

# Admin::OldRatingHistoriesController#index. Readable by officers (Ability: `can :read, OldRatingHistory`).
describe Admin::OldRatingHistoriesController, type: :controller do
  before(:each) do
    @officer = FactoryBot.create(:user, role: "officer")
    session[:user_id] = @officer.id
    @icu = FactoryBot.create(:icu_player)
    @old_tournament = OldTournament.create!(name: "Old Open", date: Date.new(2010, 4, 11), player_count: 40)
    @history = OldRatingHistory.create!(old_tournament_id: @old_tournament.id, icu_player_id: @icu.id,
                                        old_rating: 1800, new_rating: 1820, games: 5, kfactor: 20)
  end

  it "assigns the histories for the player, with their tournaments, for a full page" do
    get :index, params: { icu_player_id: @icu.id }
    expect(response).to have_http_status(:ok)
    expect(assigns(:old_rating_histories)).to eq([@history])
    expect(assigns(:icu_player)).to eq(@icu)
    expect(assigns(:old_tournament)).to be_nil
  end

  it "assigns the tournament when filtering by old tournament" do
    get :index, params: { old_tournament_id: @old_tournament.id }
    expect(assigns(:old_rating_histories)).to eq([@history])
    expect(assigns(:old_tournament)).to eq(@old_tournament)
    expect(assigns(:icu_player)).to be_nil
  end

  it "renders the player results partial for an AJAX request" do
    get :index, params: { icu_player_id: @icu.id }, xhr: true, format: :js
    expect(response).to render_template(:player_results)
  end

  it "returns the unfiltered list when no filter is given" do
    get :index
    expect(assigns(:old_rating_histories).to_a.size).to eq(1)
  end

  it "is denied to a visitor who is not logged in" do
    session[:user_id] = nil
    get :index
    expect(response).to redirect_to(log_in_path)
  end
end
