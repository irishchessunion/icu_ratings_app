require "rails_helper"

describe Admin::IcuPlayersController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "officer")
    session[:user_id] = @user.id
    @icu_player = FactoryBot.create(:icu_player)
  end

  it "lists icu players" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:icu_players)).not_to be_nil
  end

  it "lists icu players as JavaScript" do
    get :index, params: { results: "1" }, xhr: true, format: :js
    expect(response).to render_template(:results)
  end

  it "shows an icu player" do
    get :show, params: { id: @icu_player.id }
    expect(assigns(:icu_player)).to eq(@icu_player)
  end

  it "shows an icu player as JavaScript" do
    get :show, params: { id: @icu_player.id }, format: :js, xhr: true
    expect(response).to have_http_status(:ok)
  end

  it "renders the ratings graph" do
    get :graph, params: { id: @icu_player.id }, xhr: true, format: :js
    expect(response).to have_http_status(:ok)
  end
end
