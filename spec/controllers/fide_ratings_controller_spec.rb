require "rails_helper"

describe FideRatingsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "admin")
    session[:user_id] = @user.id
    @fide_rating = FactoryBot.create(:fide_rating)
  end

  it "lists fide ratings" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:fide_ratings)).not_to be_nil
  end

  it "lists fide ratings as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:results)
  end

  it "shows a fide rating graph" do
    get :show, params: { id: @fide_rating.id }, xhr: true, format: :js
    expect(response).to have_http_status(:ok)
    expect(assigns(:ratings_graph)).not_to be_nil
  end
end
