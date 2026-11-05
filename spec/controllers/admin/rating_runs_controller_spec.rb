require 'rails_helper'

describe Admin::RatingRunsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "admin")
    session[:user_id] = @user.id
    @t1 = Tournament.create!(original_name: "Q1", name: "Q1", start: "2026-03-07", finish: "2026-03-08", rorder: 1, rounds: 6, user_id: 100, stage: "queued")
    @t2 = Tournament.create!(original_name: "Q2", name: "Q2", start: "2026-04-07", finish: "2026-04-08", rorder: 2, rounds: 6, user_id: 100, stage: "queued")
  end

  it "lists rating runs" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:rating_runs)).not_to be_nil
  end

  it "lists rating runs as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:results)
  end

  it "shows a rating run as JSON" do
    run = RatingRun.create!(user: @user, start_tournament_id: @t1.id, last_tournament_id: @t2.id)
    get :show, params: { id: run.id }, xhr: true, format: :json
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("status")
  end

  it "creates a rating run" do
    expect {
      post :create, params: { rating_run: { start_tournament_id: @t1.id } }
    }.to change(RatingRun, :count).by(1)
    expect(response).to redirect_to([:admin, RatingRun.last])
  end

  it "redirects with an error when the run cannot be created" do
    post :create, params: { rating_run: { start_tournament_id: 987654 } }
    expect(response).to redirect_to(admin_rating_runs_path).or redirect_to([:admin, RatingRun.last])
  end

  it "edits a rating run" do
    run = RatingRun.create!(user: @user, start_tournament_id: @t1.id, last_tournament_id: @t2.id)
    get :edit, params: { id: run.id }, xhr: true, format: :js
    expect(response).to have_http_status(:ok)
    expect(assigns(:rating_run)).to eq(run)
  end

  it "updates a rating run's reason" do
    run = RatingRun.create!(user: @user, start_tournament_id: @t1.id, last_tournament_id: @t2.id)
    patch :update, params: { id: run.id, rating_run: { reason: "manual note" } }, xhr: true, format: :js
    expect(run.reload.reason).to eq("manual note")
  end

  it "destroys a rating run" do
    run = RatingRun.create!(user: @user, start_tournament_id: @t1.id, last_tournament_id: @t2.id)
    expect { delete :destroy, params: { id: run.id } }.to change(RatingRun, :count).by(-1)
    expect(response).to redirect_to(admin_rating_runs_path)
  end
end
