require 'rails_helper'

# Note: these tests are a little fragile because of the need to wait occasionally,
# to allow things to synchronize. It would be better to find a way to avoid that.

describe FidePlayer do
  describe "update ICU ID", js: true do
    before(:each) do
      @i = FactoryBot.create(:icu_player, id: 1350, last_name: "Orr", first_name: "Mark", fed: "IRL", dob: "1955-09-11", title: "IM", gender: "M")
      @f = FactoryBot.create(:fide_player, id: 250035, last_name: "Orr", first_name: "Mark", fed: "IRL", born: 1955, title: "IM", gender: "M", icu_player: nil)
      @link = "Link FIDE player to this ICU player"
      @unlink = "Unlink FIDE player from this ICU player"
      login("admin")
      visit fide_players_path
      page.click_link "?"
      @sleep = 0.2
      sleep @sleep
    end

    it "create a link between a FIDE and ICU player then destroy it" do
      expect(@f.icu_id).to be_nil
      page.click_link @link
      sleep @sleep
      @f.reload
      expect(@f.icu_id).to eq(@i.id)
      first(:link, @i.id.to_s).click
      sleep @sleep
      page.click_link @unlink
      sleep @sleep
      @f.reload
      expect(@f.icu_id).to be_nil
    end

    it "should create a link if FIDE name is in one part" do
      @f.update_column(:first_name, "")
      @f.update_column(:last_name, "Mark Orr")
      page.click_link @link
      sleep @sleep
      @f.reload
      expect(@f.icu_id).to eq(@i.id)
    end

    it "should not create a link if federation is mismatched" do
      @i.update_column(:fed, "SCO")
      page.click_link @link
      sleep @sleep
      page.driver.browser.switch_to.alert.dismiss
      sleep @sleep
      @f.reload
      expect(@f.icu_id).to be_nil
    end

    it "should not create a link if title is mismatched" do
      @i.update_column(:title, "GM")
      page.click_link @link
      sleep @sleep
      page.driver.browser.switch_to.alert.dismiss
      sleep @sleep
      @f.reload
      expect(@f.icu_id).to be_nil
    end

    it "should not create a link if YOB/DOB is mismatched" do
      @i.update_column(:dob, "1986-06-16")
      page.click_link @link
      sleep @sleep
      page.driver.browser.switch_to.alert.dismiss
      sleep @sleep
      @f.reload
      expect(@f.icu_id).to be_nil
    end

    it "should not create a link if gender is mismatched" do
      @i.update_column(:gender, "F")
      page.click_link @link
      sleep @sleep
      page.driver.browser.switch_to.alert.dismiss
      sleep @sleep
      @f.reload
      expect(@f.icu_id).to be_nil
    end

    it "should not create a link if both names are mismatched" do
      @i.update_column(:first_name, "Malcolm")
      @i.update_column(:last_name, "Algeo")
      page.click_link @link
      sleep @sleep
      page.driver.browser.switch_to.alert.dismiss
      sleep @sleep
      @f.reload
      expect(@f.icu_id).to be_nil
    end

    it "should create a link if only one name is mismatched" do
      @i.update_column(:first_name, "Malcolm")
      page.click_link @link
      sleep @sleep
      @f.reload
      expect(@f.icu_id).to eq(@i.id)
    end
  end
end
