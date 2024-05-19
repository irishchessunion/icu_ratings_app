require 'rails_helper'


describe RatingAdjustment do
  it "adjusts ratings on 2024-03-01" do
    r = RatingAdjustment.maybe_adjust(nil, ::Date.new(2024, 3, 1))
    expect(r).to be nil
    r = RatingAdjustment.maybe_adjust(1400, ::Date.new(2024, 3, 1))
    expect(r).to eq 1760
    r = RatingAdjustment.maybe_adjust(2100, ::Date.new(2024, 3, 1))
    expect(r).to eq 2100
  end

  it "does not adjust ratings on 2024-04-01" do
    r = RatingAdjustment.maybe_adjust(nil, ::Date.new(2024, 4, 1))
    expect(r).to be nil
    r = RatingAdjustment.maybe_adjust(1400, ::Date.new(2024, 4, 1))
    expect(r).to eq 1400
    r = RatingAdjustment.maybe_adjust(2100, ::Date.new(2024, 4, 1))
    expect(r).to eq 2100
  end
end
