require 'rails_helper'

describe Login do
  before(:each) do
    @user = FactoryBot.create(:user)
    @login = Login.create!(user: @user, ip: "127.0.0.1", problem: "none", role: "member")
  end

  it "searches by email" do
    result = Login.search({ email: @user.email }, "/path")
    expect(result.matches).to include(@login)
  end

  it "searches by icu_id" do
    result = Login.search({ icu_id: @user.icu_id }, "/path")
    expect(result.matches).to include(@login)
  end

  it "searches by first and last name" do
    result = Login.search({ first_name: @user.icu_player.first_name, last_name: @user.icu_player.last_name }, "/path")
    expect(result.matches).to include(@login)
  end

  it "searches by problem, role, and ip" do
    result = Login.search({ problem: "none", role: "member", ip: "127" }, "/path")
    expect(result.matches).to include(@login)
  end

  it "returns all when no filters" do
    result = Login.search({}, "/path")
    expect(result.matches).to include(@login)
  end
end
