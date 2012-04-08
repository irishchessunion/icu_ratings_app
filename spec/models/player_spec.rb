require 'spec_helper'

describe Player do
  context "#changed_from_original?" do
    before(:each) do
      @p = Player.new(
        first_name:  "Mark",
        last_name:   "Orr",
        icu_id:      1350,
        fide_id:     2500035,
        fed:         'IRL',
        title:       "IM",
        gender:      "M",
        dob:         "1955-11-09",
        icu_rating:  2192,
        fide_rating: 2264,
      )
      @p.num = 1
      @p.original_name = @p.name
      %w[icu_id fide_id fed title gender dob icu_rating fide_rating].each { |key| @p.send("original_#{key}=", @p.send(key)) }
      @p.save!
    end
    
    it "should not have changed" do
      @p.changed_from_original?.should be_false
    end
    
    it "should be sensitive to a change in name" do
      @p.last_name = "Fischer"
      @p.changed_from_original?.should be_true
      @p.changed_from_original?(only: :name).should be_true
      @p.changed_from_original?(only: "name").should be_true
      @p.changed_from_original?(except: :name).should be_false
      @p.changed_from_original?(except: "name").should be_false
      @p.changed_from_original?(only: [:icu_id, :fide_rating]).should be_false
      @p.changed_from_original?(only: [:name, :fide_rating]).should be_true
      @p.changed_from_original?(only: %w[name dob]).should be_true
      @p.changed_from_original?(except: [:icu_id, :fide_rating]).should be_true
      @p.changed_from_original?(except: [:name, :fide_rating]).should be_false
      @p.changed_from_original?(except: %w[name fed]).should be_false
    end
    
    it "should not be sensitive to a reversal of the original name" do
      @p.original_name = "Mark Orr"
      @p.changed_from_original?.should be_false
    end
  end
  
  context "#signature" do
    before(:each) do
      @t = test_tournament("bunratty_masters_2011.tab", 1)
    end
    
    it "should get right signature for player who played in every round" do
      p = @t.players.find_by_last_name_and_first_name("Short", "Nigel")
      p.signature.should == "1W19 2D11 3W8 4L1 5D9 6W14"
    end
    
    it "should get right signature for player who didn't play in every round" do
      p = @t.players.find_by_last_name("Cafolla")
      p.signature.should == "1L11 2D19 3W27 4W25 5L7"
    end
    
    it "should get right signature for player who didn't play in any rounds" do
      p = @t.players.find_by_last_name("Grennel")
      p.signature.should == ""
    end
  end
end
