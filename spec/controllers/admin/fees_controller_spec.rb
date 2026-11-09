require "rails_helper"

describe Admin::FeesController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "admin")
    session[:user_id] = @user.id
    @icu = FactoryBot.create(:icu_player)
    @fee = Fee.create!(icu_id: @icu.id, category: "FTR", description: "Test", status: "Completed", used: false, date: Date.today)
  end

  it "lists fees, defaulting to unused" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:fees).matches).to include(@fee)
  end

  it "lists fees as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:results)
  end

  it "toggles a fee's used flag" do
    patch :update, params: { id: @fee.id }, xhr: true, format: :js
    expect(@fee.reload.used).to be true
  end
end
