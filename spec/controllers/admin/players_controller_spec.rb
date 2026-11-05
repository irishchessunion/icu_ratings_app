require 'rails_helper'

# Admin::PlayersController. Permissions: officers and admins can manage players.
describe Admin::PlayersController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "officer")
    session[:user_id] = @user.id
    @tournament = Tournament.create!(original_name: "P", name: "P", start: "2026-03-07", finish: "2026-03-08", rorder: 1, rounds: 2, user_id: @user.id, stage: "initial")
    @player = Player.create!(first_name: "Ann", last_name: "Test", original_name: "Test, Ann", category: "icu_player", num: 1, bonus: 0, tournament_id: @tournament.id)
  end

  it "lists players" do
    get :index, xhr: true, format: :js
    expect(response).to have_http_status(:ok)
    expect(assigns(:players)).not_to be_nil
  end

  it "lists players as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:player_results)
  end

  it "shows a player" do
    get :show, params: { id: @player.id }
    expect(assigns(:player)).to eq(@player)
    expect(assigns(:tournament)).to eq(@tournament)
  end

  it "edits a player" do
    get :edit, params: { id: @player.id }, xhr: true, format: :js
    expect(assigns(:player)).to eq(@player)
    expect(assigns(:tournament)).to eq(@tournament)
  end

  it "updates a player's attributes" do
    patch :update, params: { id: @player.id, player: { first_name: "Anna" } }, xhr: true, format: :js
    expect(@player.reload.first_name).to eq("Anna")
  end

  it "updates a player from an ICU id" do
    icu = FactoryBot.create(:icu_player, first_name: "Icu", last_name: "Player")
    patch :update, params: { id: @player.id, icu_id: icu.id }, xhr: true, format: :js
    expect(@player.reload.icu_id).to eq(icu.id)
    expect(@player.first_name).to eq("Icu")
  end

  it "updates a player from a FIDE id" do
    fide = FactoryBot.create(:fide_player, first_name: "Fide", last_name: "Player", fed: "IRL", gender: "M")
    patch :update, params: { id: @player.id, fide_id: fide.id }, xhr: true, format: :js
    expect(@player.reload.fide_id).to eq(fide.id)
  end

  it "destroys a deletable player" do
    @player.update_column(:status, "ok")
    expect { delete :destroy, params: { id: @player.id } }.to change(Player, :count).by(-1)
  end

  it "refuses to destroy a player with opponents" do
    opponent = Player.create!(first_name: "Ben", last_name: "Test", original_name: "Test, Ben", category: "icu_player", num: 2, bonus: 0, tournament_id: @tournament.id)
    Result.create!(player: @player, opponent: opponent, round: 1, result: "W", colour: "W", rateable: true)
    get :show, params: { id: @player.id }
    delete :destroy, params: { id: @player.id }
    expect(response).to render_template("show")
    expect(flash.now[:alert]).to include("can't be deleted")
  end

  it "autofixes a player" do
    allow_any_instance_of(Player).to receive(:autofix)
    allow_any_instance_of(Player).to receive(:status_ok?).and_return(true)
    allow_any_instance_of(Tournament).to receive(:find_first_player_with_errors).and_return(nil)
    get :autofix, params: { id: @player.id }
    expect(response).to redirect_to([:admin, @tournament])
  end

  it "moves to the next step for a player with errors" do
    allow_any_instance_of(Player).to receive(:status_ok?).and_return(false)
    get :nextstep, params: { id: @player.id }
    expect(response).to redirect_to([:admin, @player])
  end
end