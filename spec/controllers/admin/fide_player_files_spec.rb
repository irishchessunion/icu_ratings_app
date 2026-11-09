require "rails_helper"
describe Admin::FidePlayerFilesController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "admin")
    session[:user_id] = @user.id
  end
  it "destroys a file that has not been applied" do
    file = FidePlayerFile.new(user_id: @user.id, description: "test", players_in_file: 1, new_fide_records: 0, new_icu_mappings: 0)
    file.save!(validate: false)
    expect { delete :destroy, params: { id: file.id } }.to change(FidePlayerFile, :count).by(-1)
  end
  it "refuses to delete a file that resulted in DB updates" do
    file = FidePlayerFile.new(user_id: @user.id, description: "test", players_in_file: 1, new_fide_records: 1, new_icu_mappings: 0)
    file.save!(validate: false)
    delete :destroy, params: { id: file.id }
    expect(response).to redirect_to([:admin, file])
    expect(FidePlayerFile.exists?(file.id)).to be true
  end
  it "lists fide player files" do
    get :index
    expect(response).to have_http_status(:ok)
  end
  it "shows a file" do
    file = FidePlayerFile.new(user_id: @user.id, description: "test", players_in_file: 1, new_fide_records: 0, new_icu_mappings: 0)
    file.save!(validate: false)
    get :show, params: { id: file.id }
    expect(assigns(:fide_player_file)).to eq(file)
  end
  it "renders new" do
    get :new
    expect(assigns(:fide_player_file)).to be_a(FidePlayerFile)
  end
end
