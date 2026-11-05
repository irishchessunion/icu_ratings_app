require 'rails_helper'

describe Admin::EventsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, role: "admin")
    session[:user_id] = @user.id
    @event = Event.create!(name: "Test", time: 1, success: true)
  end

  it "lists events" do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:events).matches).to include(@event)
  end

  it "lists events as JavaScript" do
    get :index, xhr: true, format: :js
    expect(response).to render_template(:results)
  end

  it "shows an event as JavaScript" do
    get :show, params: { id: @event.id }, xhr: true, format: :js
    expect(response).to have_http_status(:ok)
  end

  it "destroys an event" do
    expect { delete :destroy, params: { id: @event.id } }.to change(Event, :count).by(-1)
    expect(response).to redirect_to(admin_events_path)
  end
end
