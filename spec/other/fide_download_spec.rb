# encoding: UTF-8
require 'rails_helper'

module FIDE
  describe Download do
    before(:each) do
      @players_list = File.open("#{Rails.root}/spec/files/players_list.xml", "r:US-ASCII:UTF-8") { |f| f.read }
    end

    context "parsing xml" do
      it "sanity check" do
        expect(@players_list.length).to be > 0
        expect(@players_list.encoding.name).to eq("UTF-8")
        expect(@players_list.valid_encoding?).to be true
      end

      it "should retrieve Irish players" do
        hash = Hash.new
        sax = FIDE::Download::Parser.new do |p|
          if p["country"] == "IRL"
            player = FIDE::Download::Player.new(p)
            hash[player.id] = player
          end
        end
        parser = Nokogiri::XML::SAX::Parser.new(sax)
        parser.parse(@players_list)
        expect(hash.size).to eq(6)

        me = hash[2500035]
        expect(me.last_name).to eq("Orr")
        expect(me.first_name).to eq("Mark J L")
        expect(me.gender).to eq("M")
        expect(me.born).to eq(1955)
        expect(me.rating).to eq(2240)
        expect(me.games).to eq(0)
        expect(me.title).to eq("IM")
        expect(me.fed).to eq("IRL")
        expect(me.active).to be true

        april = hash[2500370]
        expect(april.last_name).to eq("Cronin")
        expect(april.first_name).to eq("April")
        expect(april.gender).to eq("F")
        expect(april.born).to eq(1960)
        expect(april.rating).to eq(2055)
        expect(april.games).to eq(0)
        expect(april.title).to be_nil
        expect(april.fed).to eq("IRL")
        expect(april.active).to be false

        gearoidin = hash[2501171]
        expect(gearoidin.last_name).to eq("Ui Laighleis")
        expect(gearoidin.first_name).to eq("Gearoidin")
        expect(gearoidin.gender).to eq("F")
        expect(gearoidin.born).to eq(1964)
        expect(gearoidin.rating).to eq(1894)
        expect(gearoidin.games).to eq(0)
        expect(gearoidin.title).to eq("WCM")
        expect(gearoidin.fed).to eq("IRL")
        expect(gearoidin.active).to be true

        mark = hash[2500450]
        expect(mark.last_name).to eq("Quinn")
        expect(mark.first_name).to eq("Mark")
        expect(mark.gender).to eq("M")
        expect(mark.born).to eq(1976)
        expect(mark.rating).to eq(2388)
        expect(mark.games).to eq(0)
        expect(mark.title).to eq("IM")
        expect(mark.fed).to eq("IRL")
        expect(mark.active).to be true

        bernard = hash[2500019]
        expect(bernard.last_name).to eq("Kernan")
        expect(bernard.first_name).to eq("Bernard")
        expect(bernard.gender).to eq("M")
        expect(bernard.born).to eq(1955)
        expect(bernard.rating).to eq(2380)
        expect(bernard.games).to eq(0)
        expect(bernard.title).to be_nil
        expect(bernard.fed).to eq("IRL")
        expect(bernard.active).to be false

        debbie = hash[4413504]
        expect(debbie.last_name).to eq("Quinn")
        expect(debbie.first_name).to eq("Deborah")
        expect(debbie.gender).to eq("F")
        expect(debbie.born).to eq(1969)
        expect(debbie.rating).to eq(1841)
        expect(debbie.games).to eq(0)
        expect(debbie.title).to be_nil
        expect(debbie.fed).to eq("IRL")
        expect(debbie.active).to be false

      end

      it "should retrieve foreign players" do
        hash = Hash.new
        sax = FIDE::Download::Parser.new do |p|
          unless p["country"] == "IRL" || p["flag"].to_s.match(/i/)
            player = FIDE::Download::Player.new(p)
            hash[player.id] = player
          end
        end
        parser = Nokogiri::XML::SAX::Parser.new(sax)
        parser.parse(@players_list)
        expect(hash.size).to eq(3)

        magnus = hash[1503014]
        expect(magnus.last_name).to eq("Carlsen")
        expect(magnus.first_name).to eq("Magnus")
        expect(magnus.gender).to eq("M")
        expect(magnus.born).to eq(1990)
        expect(magnus.rating).to eq(2843)
        expect(magnus.games).to eq(10)
        expect(magnus.title).to eq("GM")
        expect(magnus.fed).to eq("NOR")
        expect(magnus.active).to be true

        shakri = hash[13401319]
        expect(shakri.last_name).to eq("Mamedyarov")
        expect(shakri.first_name).to eq("Shakhriyar")
        expect(shakri.gender).to eq("M")
        expect(shakri.born).to eq(1985)
        expect(shakri.rating).to eq(2729)
        expect(shakri.games).to eq(0)
        expect(shakri.title).to eq("GM")
        expect(shakri.fed).to eq("AZE")
        expect(shakri.active).to be true

        sofia = hash[24150797]
        expect(sofia.last_name).to eq("Zyzlova")
        expect(sofia.first_name).to eq("Sofia")
        expect(sofia.gender).to eq("F")
        expect(sofia.born).to be nil
        expect(sofia.rating).to eq(2080)
        expect(sofia.games).to eq(0)
        expect(sofia.title).to be_nil
        expect(sofia.fed).to eq("RUS")
        expect(sofia.active).to be true
      end
    end

    context "updating FIDE players" do
      before(:each) do
        @mark = FidePlayer.create!(first_name: "Mark", last_name: "Quinn", fed: "IRL", gender: "M", id: 2500450, rating: 2422, icu_id: 1402)
        @shak = FidePlayer.create!(first_name: "Shakhriyar", last_name: "Mamedyarov", fed: "AZE",  gender: "M", id: 13401319, rating: 2700)
        @sofia = FidePlayer.create!(first_name: "Sofia", last_name: "Zyzlova", fed: "RUS", gender: "F", id: 24150797, icu_id: 2222)

        @download = FIDE::Download.new
        @download.start_timers
        @download.list = Date.new(2014, 3, 1)

        @players_list = File.open("#{Rails.root}/spec/files/players_list.xml", "r:US-ASCII:UTF-8") { |f| f.read }
        hash = Hash.new
        sax = FIDE::Download::Parser.new do |p|
          player = FIDE::Download::Player.new(p)
          hash[player.id] = player
        end
        parser = Nokogiri::XML::SAX::Parser.new(sax)
        parser.parse(@players_list)
        @download.update_our_players_and_ratings hash
        [@mark, @shak, @sofia].each { |p| p.reload }
      end

      it "should update player rating" do
        expect(@mark.rating).to eq(2388)
        expect(@shak.rating).to eq(2729)
        expect(@sofia.rating).to eq(2080)
      end

      it "should leave ICU IDs unchanged" do
        expect(@mark.icu_id).to eq(1402)
        expect(@shak.icu_id).to be_nil
        expect(@sofia.icu_id).to eq(2222)
      end

    end
  end
end
