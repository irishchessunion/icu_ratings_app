require 'rails_helper'

# Trying to diagnose failing selenium tests
# Chrome error: 
#
# Failed to load extension from: . Manifest file is missing or unreadable
#
# Rspec error:
#
# Failure/Error: visit "/log_in"
#
#    Selenium::WebDriver::Error::UnknownError:
#      unknown error: Chrome failed to start: exited normally
#        (unknown error: DevToolsActivePort file doesn't exist)
#        (The process started from chrome location /snap/bin/chromium is no longer running, so ChromeDriver is assuming that Chrome has crashed.)

describe "Login" do
  describe "login" do
    before(:each) do
      login("admin")
    end

    # Miminal failing test
    it "login with JS true", js: true do
    end

    # Minimal working test
    it "login without JS true" do
    end

    # example failing test from failures_spec
    #it "details", js: true do
      #FactoryGirl.create(:failure, details: "Woopsee!")
      #visit "/admin/failures"
      #click_link "Show failure details"
      #expect(page).to have_selector("pre", :text => "Woopsee!")
    #end
    
    # example passing test from failures_spec
    #it "simulation" do
      #expect(Failure.count).to eq(0)
      #expect { visit "/admin/failures/new" }.to raise_error("Simulated Failure")
      #expect(Failure.count).to eq(1)
    #end

  end
end

