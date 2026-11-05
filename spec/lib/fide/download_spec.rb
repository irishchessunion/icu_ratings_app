require 'rails_helper'

# Specs for lib/fide/download.rb. Network, zip and file I/O are stubbed. XML is built
# in the spec (small synthetic lists), so every assertion is a hand-checked value.
module FideTestHelpers
  # Builds a FIDE-style playerslist XML string from an array of player hashes.
  def self.xml_for(players)
    body = players.map do |p|
      fields = p.map { |k, v| "<#{k}>#{v}</#{k}>" }.join
      "<player>#{fields}</player>"
    end.join
    "<playerslist>#{body}</playerslist>"
  end

  def self.irish_player(id, name = nil)
    h = { fideid: id, country: "IRL", sex: "M", rating: 1500 }
    h[:name] = name || "Player#{id}, Test"
    h
  end
end

module FIDE
  describe Download::Player do
    describe "#initialize and setters" do
      it "parses basic fields" do
        p = Download::Player.new({ "fideid" => "2500035", "name" => "Orr, Mark J L", "country" => "IRL", "sex" => "M", "birthday" => "1955", "rating" => "2240", "games" => "0", "title" => "IM", "flag" => "" })
        expect(p.id).to eq(2500035)
        expect(p.last_name).to eq("Orr")
        expect(p.first_name).to eq("Mark J L")
        expect(p.fed).to eq("IRL")
        expect(p.born).to eq(1955)
        expect(p.gender).to eq("M")
        expect(p.title).to eq("IM")
        expect(p.rating).to eq(2240)
        expect(p.games).to eq(0)
        expect(p.active).to eq(true)
      end

      it "converts 0 to nil for ratings" do
        p = Download::Player.new({ "fideid" => "123", "name" => "X,Y", "country" => "IRL", "sex" => "M", "rating" => "0", "rapid_rating" => "0", "blitz_rating" => "0" })
        expect(p.rating).to be_nil
        expect(p.rapid_rating).to be_nil
        expect(p.blitz_rating).to be_nil
      end

      it "defaults gender to M if missing" do
        p = Download::Player.new({ "fideid" => "123", "name" => "X,Y", "country" => "IRL" })
        expect(p.gender).to eq("M")
      end

      it "normalises titles: lower case upper-cased, WG becomes WGM" do
        expect(Download::Player.new({ "fideid" => "1", "name" => "A,B", "country" => "RUS", "sex" => "M", "title" => "gm" }).title).to eq("GM")
        expect(Download::Player.new({ "fideid" => "2", "name" => "C,D", "country" => "RUS", "sex" => "F", "title" => "wg" }).title).to eq("WGM")
      end

      it "normalises fed to upper case" do
        p = Download::Player.new({ "fideid" => "123", "name" => "X,Y", "country" => "irl", "sex" => "M" })
        expect(p.fed).to eq("IRL")
      end

      it "only accepts 4-digit birth years starting 19 or 20" do
        expect(Download::Player.new({ "fideid" => "123", "name" => "X,Y", "country" => "IRL", "sex" => "M", "birthday" => "1985" }).born).to eq(1985)
        expect(Download::Player.new({ "fideid" => "124", "name" => "Z,W", "country" => "IRL", "sex" => "M", "birthday" => "abc" }).born).to be_nil
      end

      it "sets active false if flag contains i" do
        expect(Download::Player.new({ "fideid" => "123", "name" => "X,Y", "country" => "IRL", "sex" => "M", "flag" => "i" }).active).to eq(false)
        expect(Download::Player.new({ "fideid" => "124", "name" => "Z,W", "country" => "IRL", "sex" => "M", "flag" => "" }).active).to eq(true)
      end
    end

    describe "#invalid?" do
      it "returns false for a valid player" do
        expect(Download::Player.new({ "fideid" => "123", "name" => "X,Y", "country" => "IRL", "sex" => "M" }).invalid?).to eq(false)
      end

      it "returns the reason for missing fields" do
        expect(Download::Player.new({ "name" => "X,Y", "country" => "IRL", "sex" => "M" }).invalid?).to eq("id")
        expect(Download::Player.new({ "fideid" => "123", "country" => "IRL", "sex" => "M" }).invalid?).to eq("name")
        expect(Download::Player.new({ "fideid" => "123", "name" => "X,Y", "sex" => "M" }).invalid?).to eq("fed")
      end
    end

    describe "#to_h and #to_s" do
      it "serialises correctly" do
        p = Download::Player.new({ "fideid" => "2500035", "name" => "Orr, Mark J L", "country" => "IRL", "sex" => "M", "birthday" => "1955", "rating" => "2240", "title" => "IM" })
        h = p.to_h
        expect(h[:id]).to eq(2500035)
        expect(h[:last_name]).to eq("Orr")
        expect(p.to_s).to include("2500035|Mark J L|Orr")
      end
    end

    describe "#to_csv" do
      it "formats CSV with \\N for missing values, in fide_players column order" do
        p = Download::Player.new({ "fideid" => "123", "name" => "Smith, John", "country" => "ENG", "sex" => "M", "birthday" => "1980", "rating" => "2000", "rapid_rating" => "2100", "blitz_rating" => "1900" })
        parts = p.to_csv("2026-11-02 12:00:00", "2026-11-02 12:00:00").split(",")
        expect(parts[0]).to eq("123")
        expect(parts[1]).to eq("Smith")
        expect(parts[2]).to eq("John")
        expect(parts[3]).to eq("ENG")
        expect(parts[7]).to eq("2000")
        expect(parts[8]).to eq("\\N")
        expect(parts[11]).to eq("2100")
        expect(parts[12]).to eq("1900")
      end

      it "strips backslashes from names" do
        p = Download::Player.new({ "fideid" => "123", "name" => "O\\Brien, John", "country" => "IRL", "sex" => "M" })
        expect(p.to_csv("t", "t")).to include("OBrien")
      end
    end
  end

  describe Download::Parser do
    def parse(xml)
      results = []
      Nokogiri::XML::SAX::Parser.new(Download::Parser.new { |p| results << p }).parse(xml)
      results
    end

    it "yields one hash per player with the selected fields" do
      results = parse("<playerslist><player><fideid>123</fideid><name>Test, Player</name><country>IRL</country><sex>M</sex><rating>2000</rating></player></playerslist>")
      expect(results.size).to eq(1)
      expect(results.first["fideid"]).to eq("123")
      expect(results.first["name"]).to eq("Test, Player")
    end

    it "keeps rapid and blitz ratings" do
      results = parse("<playerslist><player><fideid>456</fideid><name>X,Y</name><country>NOR</country><sex>M</sex><rapid_rating>2850</rapid_rating><blitz_rating>2900</blitz_rating></player></playerslist>")
      expect(results.first["rapid_rating"]).to eq("2850")
      expect(results.first["blitz_rating"]).to eq("2900")
    end

    it "ignores fields it doesn't select" do
      results = parse("<playerslist><player><fideid>1</fideid><name>A,B</name><country>IRL</country><sex>M</sex><unused>zzz</unused></player></playerslist>")
      expect(results.first.keys).not_to include("unused")
    end

    it "raises SyncError on a SAX error" do
      sax = Download::Parser.new { |p| }
      expect { sax.error("bad xml") }.to raise_error(Download::SyncError, /SAX error/)
    end
  end

  describe Download do
    let(:download) { Download.new }
    let(:response) { double("Net::HTTPOK", code: "200", body: "<html></html>", content_type: "text/html") }

    before do
      allow(Time).to receive(:now).and_return(Time.parse("2026-11-02 12:00:00"))
      download.instance_variable_set(:@start, Time.now)
      download.instance_variable_set(:@time, Hash.new)
    end

    describe "#request" do
      def stub_http(code_or_response)
        http = double("Net::HTTP")
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_return(code_or_response)
        allow(URI).to receive(:parse).and_return(double("URI", host: "x", port: 443, scheme: "https", request_uri: "/"))
        http
      end

      it "makes an HTTPS request and returns the response" do
        http = stub_http(response)
        expect(http).to receive(:use_ssl=).with(true)
        expect(http).to receive(:read_timeout=).with(180)
        expect(download.send(:request, "https://ratings.fide.com/test")).to eq(response)
      end

      it "raises SyncError on timeout" do
        http = stub_http(nil)
        allow(http).to receive(:request).and_raise(Timeout::Error)
        expect { download.send(:request, "https://x/") }.to raise_error(Download::SyncError, /timed out/)
      end

      it "raises SyncError on a non-200 response" do
        stub_http(double("Response", code: "404"))
        expect { download.send(:request, "https://x/") }.to raise_error(Download::SyncError, /unexpected response/)
      end

      it "uses plain HTTP without SSL for http URLs" do
        http = double("Net::HTTP", request: response)
        allow(http).to receive(:read_timeout=)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(URI).to receive(:parse).and_return(double("URI", host: "x", port: 80, scheme: "http", request_uri: "/"))
        expect(http).not_to receive(:use_ssl=)
        expect(download.send(:request, "http://x/")).to eq(response)
      end
    end

    describe "#get_download_details" do
      let(:html) { '<a href="https://ratings.fide.com/download/players_list_xml.zip" class="tur">XML format</a><small>(02 May 2026, Sz: 45.85 MB)</small>' }

      it "extracts link, file name, list and signature" do
        allow(download).to receive(:request).with("https://ratings.fide.com/download_lists.phtml").and_return(double(body: html))
        # check_list is stubbed here: its date handling has a known bug (see PLAN.md, Known issues),
        # so this example only covers the link, file name and signature.
        allow(download).to receive(:check_list).with("1st 5 2026").and_return(Date.new(2026, 5, 1))
        download.send(:get_download_details)
        expect(download.instance_variable_get(:@link)).to eq("https://ratings.fide.com/download/players_list_xml.zip")
        expect(download.instance_variable_get(:@file)).to eq("players_list_xml_foa.xml")
        expect(download.instance_variable_get(:@signature)).to eq("https://ratings.fide.com/download/players_list_xml.zip, 2026-05-02, 45.85")
      end

      it "raises when no link is found" do
        allow(download).to receive(:request).and_return(double(body: "<html></html>"))
        expect { download.send(:get_download_details) }.to raise_error(Download::SyncError, /no links detected/)
      end

      it "raises when the note has no date" do
        bad = '<a href="https://ratings.fide.com/download/players_list_xml.zip" class="tur">XML</a><small>(nothing here, Sz: 1.0 MB)</small>'
        allow(download).to receive(:request).and_return(double(body: bad))
        expect { download.send(:get_download_details) }.to raise_error(Download::SyncError, /no updated date/)
      end
    end

    describe "#check_list" do
      it "accepts a recent date and returns it" do
        allow(Date).to receive(:today).and_return(Date.new(2026, 5, 10))
        expect(download.send(:check_list, "1st May 2026")).to eq(Date.new(2026, 5, 1))
      end

      it "raises if the list is in the future" do
        allow(Date).to receive(:today).and_return(Date.new(2026, 4, 1))
        expect { download.send(:check_list, "1st May 2026") }.to raise_error(Download::SyncError, /in the future/)
      end

      it "raises if the list is more than 90 days old" do
        allow(Date).to receive(:today).and_return(Date.new(2026, 9, 1))
        expect { download.send(:check_list, "1st May 2026") }.to raise_error(Download::SyncError, /too far in the past/)
      end

      it "raises if the date can't be parsed" do
        expect { download.send(:check_list, "invalid") }.to raise_error(Download::SyncError, /invalid rating list/)
      end
    end

    describe "#check_not_downloaded" do
      before do
        download.instance_variable_set(:@name, "Test")
        download.instance_variable_set(:@signature, "sig")
      end

      it "raises SyncInfo if the same list was already processed" do
        relation = double
        allow(Event).to receive(:where).and_return(relation)
        allow(relation).to receive(:order).and_return([double(created_at: Time.now)])
        expect { download.send(:check_not_downloaded) }.to raise_error(Download::SyncInfo, /already done/)
      end

      it "does nothing if it hasn't been processed" do
        relation = double
        allow(Event).to receive(:where).and_return(relation)
        allow(relation).to receive(:order).and_return([])
        expect { download.send(:check_not_downloaded) }.not_to raise_error
      end
    end

    describe "#download_and_save" do
      it "writes the zip body to a tempfile" do
        body = double("body", encoding: double(name: "ASCII-8BIT"))
        http_response = double("Response", content_type: "application/zip", body: body)
        allow(body).to receive(:encoding).and_return(double(name: "ASCII-8BIT"))
        allow(download).to receive(:request).with("http://x").and_return(http_response)
        tempfile = double("Tempfile")
        allow(Tempfile).to receive(:new).and_return(tempfile)
        expect(tempfile).to receive(:syswrite).with(body)
        expect(tempfile).to receive(:close)
        download.instance_variable_set(:@link, "http://x")
        download.send(:download_and_save)
        expect(download.instance_variable_get(:@zip)).to eq(tempfile)
      end

      it "raises on an unexpected content type" do
        http_response = double("Response", content_type: "text/html", body: double(encoding: double(name: "ASCII-8BIT")))
        allow(download).to receive(:request).and_return(http_response)
        expect { download.send(:download_and_save) }.to raise_error(Download::SyncError, /unexpected content-type/)
      end

      it "raises on an unexpected archive encoding" do
        http_response = double("Response", content_type: "application/zip", body: double(encoding: double(name: "UTF-8")))
        allow(download).to receive(:request).and_return(http_response)
        expect { download.send(:download_and_save) }.to raise_error(Download::SyncError, /unexpected zip archive encoding/)
      end
    end

    describe "#event" do
      it "creates an Event with the report, timing and success flag" do
        download.instance_variable_set(:@name, "Test Sync")
        download.instance_variable_set(:@start, Time.now - 10)
        allow(download).to receive(:report).and_return("report")
        expect(Event).to receive(:create).with(hash_including(name: "Test Sync", report: "report", success: true))
        download.send(:event, true)
      end
    end

    describe "#summarize_time" do
      it "formats each timer to one decimal place" do
        expect(download.send(:summarize_time, { "parse" => 1.25, "load" => 3.0 })).to eq(["seconds after parse: 1.2", "seconds after load: 3.0"])
      end
    end

    describe "#update_our_players_and_ratings" do
      before do
        download.list = Date.new(2026, 11, 1)
        download.instance_variable_set(:@list, Date.new(2026, 11, 1))
        @our_player = FidePlayer.create!(first_name: "Test", last_name: "Player", fed: "IRL", gender: "M", id: 666666)
        allow(FidePlayer).to receive(:all).and_return([@our_player])
      end

      it "raises once there are more than 10 invalid records" do
        players = {}
        11.times do |i|
          p = double("Player", to_h: {}, valid?: false, errors: double(inspect: "err"))
          players[100000 + i] = p
        end
        allow(FidePlayer).to receive(:new).and_return(double("FidePlayer", valid?: false, errors: double(inspect: "err"), changed?: false))
        expect { download.update_our_players_and_ratings(players) }.to raise_error(Download::SyncError, /too many invalid records/)
      end

      it "creates a new player and their rating" do
        player_data = Download::Player.new({ "fideid" => "888888", "name" => "New,Player", "country" => "ENG", "sex" => "M", "rating" => "2000", "games" => "5" })
        allow(FideRating).to receive(:where).and_return([])
        new_player = double("FidePlayer")
        allow(FidePlayer).to receive(:new).and_yield(new_player).and_return(new_player)
        allow(new_player).to receive(:id=)
        allow(new_player).to receive(:valid?).and_return(true)
        allow(new_player).to receive(:changed?).and_return(true)
        expect(new_player).to receive(:save).with(validation: false)
        ratings = double
        expect(new_player).to receive(:fide_ratings).and_return(ratings)
        expect(ratings).to receive(:create).with(list: Date.new(2026, 11, 1), rating: 2000, games: 5)
        download.update_our_players_and_ratings({ 888888 => player_data })
        expect(download.instance_variable_get(:@creates)).to eq([888888])
      end

      it "creates a rating for an existing player who has none on this list" do
        player_data = Download::Player.new({ "fideid" => "666666", "name" => "Test,Player", "country" => "IRL", "sex" => "M", "rating" => "2300", "games" => "15" })
        allow(FideRating).to receive(:where).and_return([])
        ratings = double
        allow(@our_player).to receive(:fide_ratings).and_return(ratings)
        expect(ratings).to receive(:create).with(list: Date.new(2026, 11, 1), rating: 2300, games: 15)
        allow(@our_player).to receive(:valid?).and_return(true)
        allow(@our_player).to receive(:changed?).and_return(false)
        download.update_our_players_and_ratings({ 666666 => player_data })
        expect(download.instance_variable_get(:@changes)[:rating]).to eq(1)
      end

      it "updates an existing rating when the rating or games change" do
        player_data = Download::Player.new({ "fideid" => "666666", "name" => "Test,Player", "country" => "IRL", "sex" => "M", "rating" => "2400", "games" => "20" })
        fr = double("FideRating", fide_id: 666666)
        allow(FideRating).to receive(:where).and_return([fr])
        expect(fr).to receive(:rating=).with(2400)
        expect(fr).to receive(:games=).with(20)
        allow(fr).to receive(:valid?).and_return(true)
        allow(fr).to receive(:changed?).and_return(true)
        expect(fr).to receive(:save).with(validation: false)
        allow(@our_player).to receive(:valid?).and_return(true)
        allow(@our_player).to receive(:changed?).and_return(false)
        download.update_our_players_and_ratings({ 666666 => player_data })
        expect(download.instance_variable_get(:@changes)[:rating]).to eq(1)
      end

      it "leaves an existing rating alone when nothing changed" do
        player_data = Download::Player.new({ "fideid" => "666666", "name" => "Test,Player", "country" => "IRL", "sex" => "M", "rating" => "2400", "games" => "20" })
        fr = double("FideRating", fide_id: 666666)
        allow(FideRating).to receive(:where).and_return([fr])
        allow(fr).to receive(:rating=)
        allow(fr).to receive(:games=)
        allow(fr).to receive(:valid?).and_return(true)
        allow(fr).to receive(:changed?).and_return(false)
        expect(fr).not_to receive(:save)
        allow(@our_player).to receive(:valid?).and_return(true)
        allow(@our_player).to receive(:changed?).and_return(false)
        download.update_our_players_and_ratings({ 666666 => player_data })
        expect(download.instance_variable_get(:@changes)[:rating]).to eq(0)
      end

      it "records an invalid rating record rather than saving it" do
        player_data = Download::Player.new({ "fideid" => "666666", "name" => "Test,Player", "country" => "IRL", "sex" => "M", "rating" => "2300", "games" => "15" })
        fr = double("FideRating", fide_id: 666666)
        allow(FideRating).to receive(:where).and_return([fr])
        allow(fr).to receive(:rating=)
        allow(fr).to receive(:games=)
        allow(fr).to receive(:valid?).and_return(false)
        allow(fr).to receive(:errors).and_return(double(inspect: "bad"))
        allow(@our_player).to receive(:valid?).and_return(true)
        allow(@our_player).to receive(:changed?).and_return(false)
        download.update_our_players_and_ratings({ 666666 => player_data })
        expect(download.instance_variable_get(:@invalid).size).to eq(1)
      end

      it "records an invalid player and skips their rating" do
        p = double("Player", id: 777777)
        allow(p).to receive(:to_h).and_return({ first_name: "X" })
        allow(FidePlayer).to receive(:new).and_return(double("FidePlayer", valid?: false, errors: double(inspect: "err"), changed?: false))
        download.update_our_players_and_ratings({ 777777 => p })
        expect(download.instance_variable_get(:@invalid).size).to eq(1)
      end
    end
  end

  describe Download::Irish do
    let(:irish) { Download::Irish.new }
    let(:zip) { double("Zip::File") }

    before do
      allow(Time).to receive(:now).and_return(Time.parse("2026-11-02 12:00:00"))
      irish.instance_variable_set(:@start, Time.now)
      irish.instance_variable_set(:@time, Hash.new)
      irish.instance_variable_set(:@zip, double(path: "/tmp/x"))
      irish.instance_variable_set(:@file, "players_list_xml_foa.xml")
      allow(Zip::File).to receive(:open).and_return(zip)
    end

    def zip_returns(data, entry: true)
      allow(zip).to receive(:find_entry).with("players_list_xml_foa.xml").and_return(entry ? double : nil)
      allow(zip).to receive(:read).and_return(data)
    end

    # 201 valid Irish players (the check is "more than 200") plus whatever extras the example adds.
    def irish_list(extra = [])
      FideTestHelpers.xml_for((1..201).map { |i| FideTestHelpers.irish_player(1000000 + i) } + extra)
    end

    describe "#read_and_parse" do
      it "extracts every Irish player from a valid list" do
        zip_returns(irish_list)
        irish.send(:read_and_parse)
        players = irish.instance_variable_get(:@their_players)
        expect(players.size).to eq(201)
        expect(players[1000001].fed).to eq("IRL")
        expect(players[1000001].last_name).to eq("Player1000001")
      end

      it "ignores non-Irish players" do
        zip_returns(irish_list([{ fideid: 2000001, name: "Magnus, C", country: "NOR", sex: "M" }]))
        irish.send(:read_and_parse)
        expect(irish.instance_variable_get(:@their_players).size).to eq(201)
      end

      it "raises if the zip has no entry for the file" do
        zip_returns(irish_list, entry: false)
        expect { irish.send(:read_and_parse) }.to raise_error(Download::SyncError, /zip file has no entry/)
      end

      it "raises on an unexpected encoding" do
        zip_returns(irish_list.encode("UTF-16LE"))
        expect { irish.send(:read_and_parse) }.to raise_error(Download::SyncError, /unexpected zip data encoding \(UTF-16LE\)/)
      end

      it "converts binary ISO-8859-1 data to UTF-8 before parsing" do
        name_utf8 = "Ó Súilleabháin, Seán"
        xml = irish_list([{ fideid: 2000002, name: name_utf8, country: "IRL", sex: "M" }])
        binary = xml.encode("ISO-8859-1").force_encoding("ASCII-8BIT")
        zip_returns(binary)
        irish.send(:read_and_parse)
        players = irish.instance_variable_get(:@their_players)
        expect(players[2000002].last_name).to eq("Ó Súilleabháin")
        expect(players[2000002].first_name).to eq("Seán")
      end

      it "raises if the XML is malformed" do
        zip_returns("<playerslist><player>")
        expect { irish.send(:read_and_parse) }.to raise_error(Download::SyncError, /failed to parse XML data/)
      end

      it "raises if 200 or fewer Irish players are found" do
        zip_returns(FideTestHelpers.xml_for((1..200).map { |i| FideTestHelpers.irish_player(1000000 + i) }))
        expect { irish.send(:read_and_parse) }.to raise_error(Download::SyncError, /not enough Irish players found: 200/)
      end

      it "raises if any Irish player is invalid, listing the examples" do
        zip_returns(irish_list([{ fideid: 2000003, country: "IRL", sex: "M" }]))
        expect { irish.send(:read_and_parse) }.to raise_error(Download::SyncError, /too many invalid players \(1\)/)
      end

      it "records the parse time" do
        zip_returns(irish_list)
        irish.send(:read_and_parse)
        expect(irish.instance_variable_get(:@time)).to have_key("parse")
      end
    end

    describe "#sync_fide_players" do
      before { allow(irish).to receive(:start_timers) }

      it "runs the full flow and logs success" do
        %i[get_download_details check_not_downloaded download_and_save read_and_parse update_our_players_and_ratings].each { |m| allow(irish).to receive(m) }
        expect(irish).to receive(:event).with(true)
        irish.sync_fide_players(false)
      end

      it "skips the duplicate check when forced" do
        %i[get_download_details download_and_save read_and_parse update_our_players_and_ratings].each { |m| allow(irish).to receive(m) }
        expect(irish).not_to receive(:check_not_downloaded)
        allow(irish).to receive(:event)
        irish.sync_fide_players(true)
      end

      it "logs success with the info message on SyncInfo" do
        allow(irish).to receive(:get_download_details).and_raise(Download::SyncInfo.new("already done"))
        expect(irish).to receive(:event).with(true)
        irish.sync_fide_players(false)
        expect(irish.instance_variable_get(:@info)).to eq("already done")
      end

      it "logs failure on SyncError" do
        allow(irish).to receive(:get_download_details).and_raise(Download::SyncError.new("failed"))
        expect(irish).to receive(:event).with(false)
        irish.sync_fide_players(false)
        expect(irish.instance_variable_get(:@error)).to eq("failed")
      end

      it "logs failure with a backtrace on any other error" do
        allow(irish).to receive(:get_download_details).and_raise(RuntimeError.new("boom"))
        expect(irish).to receive(:event).with(false)
        irish.sync_fide_players(false)
        expect(irish.instance_variable_get(:@error)).to start_with("boom")
      end
    end

    describe "#report" do
      it "includes the counts, changes and timings that are set" do
        irish.instance_variable_set(:@link, "http://x")
        irish.instance_variable_set(:@their_players, { 1 => nil, 2 => nil })
        irish.instance_variable_set(:@our_players, { 1 => nil })
        irish.instance_variable_set(:@creates, [2])
        irish.instance_variable_set(:@updates, [])
        irish.instance_variable_set(:@changes, { rating: 1 })
        irish.instance_variable_set(:@time, { "parse" => 1.0 })
        report = irish.send(:report)
        expect(report).to include("link: http://x")
        expect(report).to include("records extracted: 2")
        expect(report).to include("records existing: 1")
        expect(report).to include("creates: 1: 2")
        expect(report).to include("updates: none")
        expect(report).to include("changes: rating: 1")
        expect(report).to include("seconds after parse: 1.0")
      end
    end

    describe "report helpers" do
      it "summarises a short list in full and a long one with ellipsis" do
        expect(irish.send(:summarize_list, [])).to eq("none")
        expect(irish.send(:summarize_list, [3, 1, 2])).to eq("3: 1, 2, 3")
        expect(irish.send(:summarize_list, [1, 2, 3, 4, 5, 6])).to eq("6: 1, 2, 3, 4 ... 6")
      end

      it "summarises changes sorted by key" do
        irish.instance_variable_set(:@changes, { rating: 5, games: 2 })
        expect(irish.send(:summarize_changes)).to eq("games: 2, rating: 5")
      end

      it "summarises invalid records" do
        irish.instance_variable_set(:@invalid, [])
        expect(irish.send(:summarize_invalid)).to eq("none")
        irish.instance_variable_set(:@invalid, ["1 error", "2 error"])
        expect(irish.send(:summarize_invalid)).to eq("2\n1 error\n2 error")
      end
    end
  end

  describe Download::Other do
    let(:other) { Download::Other.new }
    let(:zip) { double("Zip::File") }

    before do
      allow(Time).to receive(:now).and_return(Time.parse("2026-11-02 12:00:00"))
      other.instance_variable_set(:@start, Time.now)
      other.instance_variable_set(:@time, Hash.new)
      other.instance_variable_set(:@zip, double(path: "/tmp/x"))
      other.instance_variable_set(:@file, "players_list_xml_foa.xml")
      allow(Zip::File).to receive(:open).and_return(zip)
      allow(zip).to receive(:find_entry).and_return(double)
    end

    describe "#read_parse_and_save" do
      # A small list: the parser still runs every filter branch, but the sanity check
      # (over 120,000 records) then raises, which is itself worth asserting.
      before do
        FidePlayer.create!(first_name: "Foreign", last_name: "Icu", fed: "ENG", gender: "M", id: 3000002, icu_id: 42)
        list = FideTestHelpers.xml_for([
          { fideid: 2000001, name: "Irish, A", country: "IRL", sex: "M" },
          { fideid: 3000009, name: "Old, Timer", country: "ENG", sex: "M", flag: "i" },
          { fideid: 3000001, name: "Smith, John", country: "ENG", sex: "M", rating: 2000 },
          { fideid: 3000002, name: "Icu, Foreign", country: "ENG", sex: "M" },
          { fideid: 3000001, name: "Smith, John", country: "ENG", sex: "M" },
          { fideid: 3000003, country: "ENG", sex: "M" }
        ])
        allow(zip).to receive(:read).and_return(list)
        allow(File).to receive(:open).and_call_original
      end

      it "classifies each player: Irish, inactive, foreign ICU, duplicate and invalid" do
        expect { other.send(:read_parse_and_save) }.to raise_error(Download::SyncError, /unexpectedly low total number of records: 6/)
        expect(other.instance_variable_get(:@irish)).to eq(1)
        expect(other.instance_variable_get(:@inactive)).to eq(1)
        expect(other.instance_variable_get(:@records)).to eq(1)
        expect(other.instance_variable_get(:@invalid)).to eq({ "duplicate" => 1, "name" => 1 })
        expect(other.instance_variable_get(:@foreign_icu_players).keys).to eq([3000002])
      end

      it "writes the usable players to the CSV file" do
        expect { other.send(:read_parse_and_save) }.to raise_error(Download::SyncError)
        csv = File.read("#{Rails.root}/tmp/other_fide_players.csv")
        expect(csv.lines.size).to eq(1)
        expect(csv).to start_with("3000001,Smith,John,ENG")
      end

      it "converts binary ISO-8859-1 data to UTF-8 before parsing" do
        xml = FideTestHelpers.xml_for([{ fideid: 3000010, name: "Ó Súilleabháin, Seán", country: "ENG", sex: "M" }])
        allow(zip).to receive(:read).and_return(xml.encode("ISO-8859-1").force_encoding("ASCII-8BIT"))
        expect { other.send(:read_parse_and_save) }.to raise_error(Download::SyncError, /unexpectedly low total/)
        csv = File.read("#{Rails.root}/tmp/other_fide_players.csv", encoding: "UTF-8")
        expect(csv).to include("3000010,Ó Súilleabháin,Seán,ENG")
      end

      it "raises if the parse fails" do
        allow(zip).to receive(:read).and_return("<playerslist><player>")
        expect { other.send(:read_parse_and_save) }.to raise_error(Download::SyncError, /failed to parse XML data/)
      end

      it "raises on an unexpected encoding" do
        allow(zip).to receive(:read).and_return("<playerslist/>".encode("UTF-16LE"))
        expect { other.send(:read_parse_and_save) }.to raise_error(Download::SyncError, /unexpected zip data encoding/)
      end
    end

    describe "#load_into_mysql" do
      it "loads the CSV with REPLACE and records counts before and after" do
        allow(File).to receive(:size?).and_return(10)
        allow(FidePlayer).to receive(:count).and_return(100000, 101000)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(/LOAD DATA LOCAL INFILE.*REPLACE INTO TABLE fide_players/)
        other.instance_variable_set(:@csv, "/tmp/other_fide_players.csv")
        other.send(:load_into_mysql)
        expect(other.instance_variable_get(:@records_before_load)).to eq(100000)
        expect(other.instance_variable_get(:@records_after_load)).to eq(101000)
      end

      it "raises if the CSV is missing or empty" do
        allow(File).to receive(:size?).and_return(nil)
        other.instance_variable_set(:@csv, "/tmp/missing.csv")
        expect { other.send(:load_into_mysql) }.to raise_error(Download::SyncError, /does not exist or is empty/)
      end
    end

    describe "#sync_fide_players" do
      before { allow(other).to receive(:start_timers) }

      it "runs the full flow and logs success" do
        %i[get_download_details check_not_downloaded download_and_save read_parse_and_save update_our_players_and_ratings load_into_mysql].each { |m| allow(other).to receive(m) }
        expect(other).to receive(:event).with(true)
        other.sync_fide_players(false)
      end

      it "logs success with the info message on SyncInfo" do
        allow(other).to receive(:get_download_details).and_raise(Download::SyncInfo.new("already done"))
        expect(other).to receive(:event).with(true)
        other.sync_fide_players(false)
        expect(other.instance_variable_get(:@info)).to eq("already done")
      end

      it "logs failure on SyncError" do
        allow(other).to receive(:get_download_details).and_raise(Download::SyncError.new("failed"))
        expect(other).to receive(:event).with(false)
        other.sync_fide_players(false)
      end

      it "logs failure with a backtrace on any other error" do
        allow(other).to receive(:get_download_details).and_raise(RuntimeError.new("boom"))
        expect(other).to receive(:event).with(false)
        other.sync_fide_players(false)
        expect(other.instance_variable_get(:@error)).to start_with("boom")
      end
    end

    describe "#report and #summarize_invalid" do
      it "summarises the invalid reasons alphabetically" do
        other.instance_variable_set(:@invalid, Hash.new(0).merge("name" => 2, "duplicate" => 1))
        expect(other.send(:summarize_invalid)).to eq("duplicate: 1, name: 2")
      end

      it "reports the counts that are set" do
        other.instance_variable_set(:@count, 10)
        other.instance_variable_set(:@records, 4)
        other.instance_variable_set(:@inactive, 3)
        other.instance_variable_set(:@irish, 2)
        other.instance_variable_set(:@records_before_load, 100)
        other.instance_variable_set(:@records_after_load, 104)
        report = other.send(:report)
        expect(report).to include("total records: 10")
        expect(report).to include("records used: 4")
        expect(report).to include("inactive players skipped: 3")
        expect(report).to include("Irish players skipped: 2")
        expect(report).to include("records after load: 104")
      end
    end
  end
end
