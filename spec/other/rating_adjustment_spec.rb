require 'rails_helper'

describe ICU::RatingAdjustment do
  it "adjusts ratings on 2024-04-01" do
    r = ICU::RatingAdjustment.maybe_adjust(nil, ::Date.new(2024, 4, 1))
    expect(r).to be nil
    r = ICU::RatingAdjustment.maybe_adjust(1400, ::Date.new(2024, 4, 1))
    expect(r).to eq 1760
    r = ICU::RatingAdjustment.maybe_adjust(2100, ::Date.new(2024, 4, 1))
    expect(r).to eq 2100
  end

  it "does not adjust ratings on 2024-03-01" do
    r = ICU::RatingAdjustment.maybe_adjust(nil, ::Date.new(2024, 3, 1))
    expect(r).to be nil
    r = ICU::RatingAdjustment.maybe_adjust(1400, ::Date.new(2024, 3, 1))
    expect(r).to eq 1400
    r = ICU::RatingAdjustment.maybe_adjust(2100, ::Date.new(2024, 3, 1))
    expect(r).to eq 2100
  end
end
