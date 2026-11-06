require "rails_helper"

describe Admin::FailuresController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "admin")
    session[:user_id] = @user.id
    @failure = Failure.create!(name: "RuntimeError", details: "boom")
  end

  it "lists failures" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:failures).matches).to include(@failure)
  end

  it "lists failures as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:results)
  end

  it "shows a failure" do
    get :show, params: { id: @failure.id }, xhr: true, format: :js
    expect(response).to have_http_status(:ok)
    expect(assigns(:failure)).to eq(@failure)
  end

  it "raises the simulated failure on new" do
    expect { get :new }.to raise_error("Simulated Failure")
  end

  it "destroys a failure" do
    expect { delete :destroy, params: { id: @failure.id } }.to change(Failure, :count).by(-1)
    expect(response).to redirect_to(admin_failures_path)
  end
end
