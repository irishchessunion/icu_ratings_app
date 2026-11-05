require 'rails_helper'

# ArticlesController: public read, create/update/destroy need `can :manage, Article`
# (officers and admins). Reporters can read and create; members can read.
describe ArticlesController, type: :controller do
  before(:each) do
    @officer = FactoryBot.create(:user, role: "officer")
    @member = FactoryBot.create(:user, role: "member")
    @article = FactoryBot.create(:article, user: @officer, published: true)
  end

  it "lists articles" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:articles)).not_to be_nil
  end

  it "lists articles as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:results)
  end

  it "shows an article" do
    get :show, params: { id: @article.id }
    expect(response).to have_http_status(:ok)
  end

  it "shows an article as plain text" do
    get :show, params: { id: @article.id }, format: :text
    expect(response.content_type).to include("text/plain")
  end

  it "renders the new form" do
    session[:user_id] = @officer.id
    get :new
    expect(response).to have_http_status(:ok)
  end

  it "creates an article" do
    session[:user_id] = @officer.id
    expect {
      post :create, params: { article: { headline: "H", story: "S", published: true } }
    }.to change(Article, :count).by(1)
    expect(response).to redirect_to(Article.last)
  end

  it "cancels creation" do
    session[:user_id] = @officer.id
    expect {
      post :create, params: { article: { headline: "H", story: "S", published: true }, commit: "Cancel" }
    }.not_to change(Article, :count)
    expect(response).to redirect_to(articles_path)
  end

  it "re-renders new on a validation error" do
    session[:user_id] = @officer.id
    post :create, params: { article: { headline: "", story: "", published: true } }
    expect(response).to render_template(:new)
  end

  it "renders the edit form" do
    session[:user_id] = @officer.id
    get :edit, params: { id: @article.id }
    expect(response).to have_http_status(:ok)
  end

  it "updates an article" do
    session[:user_id] = @officer.id
    patch :update, params: { id: @article.id, article: { headline: "New" } }
    expect(@article.reload.headline).to eq("New")
    expect(response).to redirect_to(@article)
  end

  it "cancels an update" do
    session[:user_id] = @officer.id
    patch :update, params: { id: @article.id, article: { headline: "New" }, commit: "Cancel" }
    expect(@article.reload.headline).not_to eq("New")
    expect(response).to redirect_to(@article)
  end

  it "re-renders edit on a validation error" do
    session[:user_id] = @officer.id
    patch :update, params: { id: @article.id, article: { headline: "", story: "" } }
    expect(response).to render_template(:edit)
  end

  it "destroys an article" do
    session[:user_id] = @officer.id
    expect { delete :destroy, params: { id: @article.id } }.to change(Article, :count).by(-1)
    expect(response).to redirect_to(articles_path)
  end

  it "is denied to a member" do
    session[:user_id] = @member.id
    get :new
    expect(response).to redirect_to(log_in_path)
  end
end