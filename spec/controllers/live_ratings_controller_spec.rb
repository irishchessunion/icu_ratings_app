require 'rails_helper'

describe LiveRatingsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "officer")
    session[:user_id] = @user.id
  end

  it "lists live ratings" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:live_ratings)).not_to be_nil
  end

  it "lists live ratings as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:results)
  end
end
