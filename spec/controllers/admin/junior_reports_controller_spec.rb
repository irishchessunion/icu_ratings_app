require 'rails_helper'

# Admin::JuniorReportsController#show sends a CSV. Only officers and admins may read it
# (Ability: officers `can :read, JuniorReport`, admins `can :manage, :all`).
describe Admin::JuniorReportsController, type: :controller do
  it "sends the CSV header row to an officer, as an inline attachment" do
    session[:user_id] = FactoryBot.create(:user, role: "officer").id
    get :show
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.headers["Content-Disposition"]).to include("inline")
    expect(response.headers["Content-Disposition"]).to include("JuniorReport.csv")
    expect(response.body).to eq("ICU id,Name,Title,Fed,Rating,High Tide,Full?,YOB,M/F,Club,Email,Login users,Phone nr")
  end

  it "is denied to a member" do
    session[:user_id] = FactoryBot.create(:user, role: "member").id
    get :show
    expect(response).to redirect_to(log_in_path)
  end

  it "is denied to a visitor who is not logged in" do
    get :show
    expect(response).to redirect_to(log_in_path)
  end
end
