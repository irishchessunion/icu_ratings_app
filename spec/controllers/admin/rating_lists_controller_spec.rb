require 'rails_helper'

describe Admin::RatingListsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "officer")
    session[:user_id] = @user.id
    @list = RatingList.create!(date: Date.new(2026, 10, 1), tournament_cut_off: Date.new(2026, 10, 15), payment_cut_off: Date.new(2026, 10, 31))
  end

  it "lists rating lists" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:rating_lists)).not_to be_nil
  end

  it "lists rating lists as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:results)
  end

  it "shows a rating list" do
    get :show, params: { id: @list.id }
    expect(response).to have_http_status(:ok)
    expect(assigns(:rating_list)).to eq(@list)
    expect(assigns(:publications)).not_to be_nil
  end

  it "edits a rating list" do
    get :edit, params: { id: @list.id }, xhr: true, format: :js
    expect(assigns(:rating_list)).to eq(@list)
  end

  it "updates a rating list's cut-off dates" do
    patch :update, params: { id: @list.id, rating_list: { tournament_cut_off: "2026-10-20", payment_cut_off: "2026-11-01" } }, xhr: true, format: :js
    expect(@list.reload.tournament_cut_off).to eq(Date.new(2026, 10, 20))
  end
end
