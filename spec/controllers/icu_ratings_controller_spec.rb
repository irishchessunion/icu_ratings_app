require 'rails_helper'

# IcuRatingsController: public read, officers can do more. Covers the CSV export,
# the ratings graph, and the war/juniors/seniors/women/improvers reports, which each
# render an index view (or a results view for an AJAX request).
describe IcuRatingsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "officer")
    session[:user_id] = @user.id
    @icu_rating = FactoryBot.create(:icu_rating, icu_player: FactoryBot.create(:icu_player), rating: 1500, full: true)
  end

  describe "GET index" do
    it "lists icu ratings" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:icu_ratings)).not_to be_nil
    end

    it "lists icu ratings as JavaScript" do
      get :index, xhr: true, format: :js
      expect(response).to render_template(:results)
    end

    it "exports CSV when commit is CSV and a list is given" do
      get :index, params: { commit: "CSV", list: "2011-09-01" }
      expect(response.content_type).to include("text/csv")
    end

    it "exports an empty CSV when commit is CSV but no list is given" do
      get :index, params: { commit: "CSV" }
      expect(response.content_type).to include("text/csv")
    end
  end

  describe "GET show" do
    it "shows an icu rating graph" do
      get :show, params: { id: @icu_rating.id }, xhr: true, format: :js
      expect(response).to have_http_status(:ok)
      expect(assigns(:ratings_graph)).not_to be_nil
    end
  end

  # Each report renders its own index view for a normal request, and a results view
  # for an AJAX request.
  {
    war: "war",
    juniors: "juniors",
    seniors: "seniors",
    women: "women",
    improvers: "improvers"
  }.each do |action, group|
    describe "GET #{action}" do
      it "renders the #{group} index view" do
        get action
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("icu_ratings/#{group}/index")
      end

      it "renders the #{group} results view for an AJAX request" do
        get action, xhr: true, format: :js
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("icu_ratings/#{group}/results")
      end
    end
  end
end
