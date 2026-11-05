require 'rails_helper'

# Admin::PublicationsController. Permissions come from Ability: officers may create
# publications, admins may do everything. Publishing logic itself is covered in
# spec/models/rating_list_publication_spec.rb, so RatingList#publish is stubbed here.
describe Admin::PublicationsController, type: :controller do
  render_views

  before(:each) do
    @list = RatingList.create!(date: Date.new(2026, 10, 1), tournament_cut_off: Date.new(2026, 10, 15), payment_cut_off: Date.new(2026, 10, 31))
    @tournament = Tournament.create!(original_name: "T", name: "T", start: "2026-09-18", finish: "2026-09-20", rorder: 1, rounds: 6, user_id: 100, stage: "rated")
    @pub = @list.publications.create!(total: 2, creates: 1, remains: 0, updates: 1, deletes: 0, report: "report text", last_tournament_id: @tournament.id)
    @officer = FactoryBot.create(:user, role: "officer")
    @admin = FactoryBot.create(:user, role: "admin")
    @member = FactoryBot.create(:user, role: "member")
  end

  def login_as(user)
    session[:user_id] = user.id
  end

  describe "POST create" do
    it "publishes and returns the publications list as JavaScript" do
      login_as(@officer)
      allow_any_instance_of(RatingList).to receive(:publish).and_return(false)
      post :create, params: { rating_list_id: @list.id }, xhr: true, format: :js
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("#publications")
    end

    it "shows the message from publish when it fails" do
      login_as(@admin)
      allow_any_instance_of(RatingList).to receive(:publish).and_return("no subscriptions found")
      post :create, params: { rating_list_id: @list.id }, xhr: true, format: :js
      expect(response.body).to include("no subscriptions found")
    end

    it "is denied to a member" do
      login_as(@member)
      expect(RatingList).not_to receive(:find)
      post :create, params: { rating_list_id: @list.id }, xhr: true, format: :js
      expect(response.body).to include("Not authorized")
    end

    it "is denied to a visitor who is not logged in" do
      post :create, params: { rating_list_id: @list.id }
      expect(response).to redirect_to(log_in_path)
    end

    it "raises RecordNotFound for an unknown list" do
      login_as(@admin)
      expect { post :create, params: { rating_list_id: 987654 }, xhr: true, format: :js }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET show" do
    it "assigns the publication to an admin" do
      login_as(@admin)
      get :show, params: { rating_list_id: @list.id, id: @pub.id }, xhr: true, format: :js
      expect(assigns(:publication)).to eq(@pub)
      expect(response).to have_http_status(:ok)
    end

    it "is allowed to an officer (read)" do
      login_as(@officer)
      get :show, params: { rating_list_id: @list.id, id: @pub.id }, xhr: true, format: :js
      expect(assigns(:publication)).to eq(@pub)
    end
  end

  describe "GET edit" do
    it "assigns the publication and its list to an admin" do
      login_as(@admin)
      get :edit, params: { rating_list_id: @list.id, id: @pub.id }, xhr: true, format: :js
      expect(assigns(:publication)).to eq(@pub)
      expect(assigns(:rating_list)).to eq(@list)
    end

    it "is denied to an officer, who can create but not edit publications" do
      login_as(@officer)
      get :edit, params: { rating_list_id: @list.id, id: @pub.id }, xhr: true, format: :js
      expect(assigns(:publication)).to be_nil
      expect(response.body).to include("Not authorized")
    end
  end

  describe "PATCH update" do
    it "saves the notes for an admin" do
      login_as(@admin)
      patch :update, params: { rating_list_id: @list.id, id: @pub.id, publication: { notes: "checked by hand" } }, xhr: true, format: :js
      expect(@pub.reload.notes).to eq("checked by hand")
      expect(response.body).to include("dialog_update_publication")
    end

    it "only changes the permitted attribute (notes)" do
      login_as(@admin)
      patch :update, params: { rating_list_id: @list.id, id: @pub.id, publication: { notes: "n", total: 999, report: "changed" } }, xhr: true, format: :js
      @pub.reload
      expect(@pub.total).to eq(2)
      expect(@pub.report).to eq("report text")
      expect(@pub.notes).to eq("n")
    end

    it "is denied to an officer" do
      login_as(@officer)
      patch :update, params: { rating_list_id: @list.id, id: @pub.id, publication: { notes: "nope" } }, xhr: true, format: :js
      expect(@pub.reload.notes).to be_nil
    end

    it "shows the error dialog when the save fails" do
      login_as(@admin)
      allow_any_instance_of(Publication).to receive(:update) do |pub|
        pub.errors.add(:notes, "is not allowed")
        false
      end
      patch :update, params: { rating_list_id: @list.id, id: @pub.id, publication: { notes: "x" } }, xhr: true, format: :js
      expect(response.body).to include("Error updating publication notes")
    end
  end
end
