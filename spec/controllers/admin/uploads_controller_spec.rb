require 'rails_helper'

describe Admin::UploadsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "officer")
    session[:user_id] = @user.id
  end

  it "renders new when the upload is invalid" do
    post :create, params: { upload: { format: "" } }
    expect(response).to render_template(:new)
  end

  it "refuses to delete an upload associated with a tournament" do
    upload = Upload.new(user: @user, format: Upload::DEFAULT_FORMAT)
    upload.save!(validate: false)
    tournament = Tournament.create!(original_name: "U", name: "U", start: "2026-03-07", finish: "2026-03-08", rorder: 1, rounds: 2, user_id: @user.id, stage: "initial")
    upload.update_column(:tournament_id, tournament.id)
    delete :destroy, params: { id: upload.id }
    expect(response).to redirect_to([:admin, upload])
    expect(Upload.exists?(upload.id)).to be true
  end
end
