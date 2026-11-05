require 'rails_helper'

# PlayersController#show. Any member can see a player (Ability: members `can :show, Player`).
describe PlayersController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "member")
    @tournament = Tournament.create!(original_name: "Show T", name: "Show T", start: "2026-09-18", finish: "2026-09-20", rorder: 1, rounds: 6, user_id: @user.id, stage: "rated")
    @player = Player.new(first_name: "Ann", last_name: "Test", original_name: "Test, Ann", category: "icu_player", num: 1, bonus: 0, tournament_id: @tournament.id)
    @player.save!(validate: false)
  end

  it "shows a player's tournament and results to a logged-in member" do
    session[:user_id] = @user.id
    get :show, params: { id: @player.id }
    expect(response).to have_http_status(:ok)
    expect(assigns(:player)).to eq(@player)
    expect(assigns(:tournament)).to eq(@tournament)
  end

  it "loads the published bonus points article" do
    article = FactoryBot.create(:article, identity: "bonus points", published: true, user: @user)
    session[:user_id] = @user.id
    get :show, params: { id: @player.id }
    expect(assigns(:bonus_article)).to eq(article)
  end

  it "has no bonus points article when none is published" do
    FactoryBot.create(:article, identity: "bonus points", published: false, user: @user)
    session[:user_id] = @user.id
    get :show, params: { id: @player.id }
    expect(assigns(:bonus_article)).to be_nil
  end

  it "is denied to a visitor who is not logged in" do
    get :show, params: { id: @player.id }
    expect(response).to redirect_to(log_in_path)
  end

  it "raises RecordNotFound for an unknown player" do
    session[:user_id] = @user.id
    expect { get :show, params: { id: 987654 } }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
