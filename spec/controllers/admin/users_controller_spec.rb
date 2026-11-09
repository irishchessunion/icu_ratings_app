require "rails_helper"

describe Admin::UsersController, type: :controller do
  before(:each) do
    @admin = FactoryBot.create(:user, role: "admin")
    session[:user_id] = @admin.id
    @user = FactoryBot.create(:user, role: "member")
  end

  it "lists users" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:users)).not_to be_nil
  end

  it "lists users as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:results)
  end

  it "edits a user" do
    get :edit, params: { id: @user.id }, xhr: true, format: :js
    expect(assigns(:user)).to eq(@user)
  end

  it "updates a user's role and status" do
    patch :update, params: { id: @user.id, user: { role: "reporter", status: "ok" } }, xhr: true, format: :js
    expect(@user.reload.role).to eq("reporter")
  end
end
