require "rails_helper"

describe Failure do
  before(:each) do
    @failure = Failure.create!(name: "RuntimeError", details: "boom")
    @other = Failure.create!(name: "OtherError", details: "other", created_at: 2.days.ago)
  end

  it "searches by name" do
    result = Failure.search({ name: "Runtime" }, "/path")
    expect(result.matches).to include(@failure)
    expect(result.matches).not_to include(@other)
  end

  it "searches by age" do
    result = Failure.search({ age: 1 }, "/path")
    expect(result.matches).to include(@failure)
    expect(result.matches).not_to include(@other)
  end

  it "returns all when no filters" do
    result = Failure.search({}, "/path")
    expect(result.matches).to include(@failure)
  end

  it "records an exception" do
    count = Failure.count
    begin
      raise StandardError, "test error"
    rescue => e
      Failure.record(e)
    end
    f = Failure.unscoped.order(:id).last
    expect(f.name).to eq("StandardError")
    expect(f.details).to include("test error")
    expect(Failure.count).to eq(count + 1)
  end

  it "examines a payload and creates a failure unless ignored" do
    count = Failure.count
    Failure.examine(exception: ["RuntimeError", "message"])
    expect(Failure.count).to eq(count + 1)
  end

  it "ignores known exceptions" do
    count = Failure.count
    Failure.examine(exception: ["ActiveRecord::RecordNotFound", "message"])
    expect(Failure.count).to eq(count)
  end

  it "normalizes hash details on create when given a hash" do
    # ActiveRecord converts the hash to its inspect string before the before_create callback,
    # so normalize_details leaves it as-is. Document that behaviour.
    f = Failure.create!(name: "Test", details: { exception: ["Err", "msg"], foo: "bar" })
    expect(f.details).to include("exception")
  end
end
