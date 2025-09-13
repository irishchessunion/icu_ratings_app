# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

seed_sample_data = false

if seed_sample_data
  ActiveRecord::Base.transaction do
        # Users
        User.create!([
          { email: "alice@example.com", preferred_email: "alice@alt.com", password: "password1", role: "admin", icu_id: 1, status: "ok", expiry: "01-01-2030" },
          { email: "bob@example.com", preferred_email: "bob@alt.com", password: "password2", role: "member", icu_id: 2, status: "ok", expiry: "01-01-2030" },
          { email: "carol@example.com", preferred_email: "carol@alt.com", password: "password3", role: "member", icu_id: 3, status: "ok", expiry: "01-01-2030" },
          { email: "dave@example.com", preferred_email: "dave@alt.com", password: "password4", role: "member", icu_id: 4, status: "ok", expiry: "01-01-2030" },
          { email: "eve@example.com", preferred_email: "eve@alt.com", password: "password5", role: "member", icu_id: 5, status: "ok", expiry: "01-01-2030" }
        ])

        # Articles
        Article.create!([
          { headline: "Chess News 1", story: "Story 1", user_id: 1, published: true, identity: "A1" },
          { headline: "Chess News 2", story: "Story 2", user_id: 2, published: false, identity: "A2" },
          { headline: "Chess News 3", story: "Story 3", user_id: 3, published: true, identity: "A3" },
          { headline: "Chess News 4", story: "Story 4", user_id: 4, published: false, identity: "A4" },
          { headline: "Chess News 5", story: "Story 5", user_id: 5, published: true, identity: "A5" }
        ])

        # Downloads
        Download.create!([
          { comment: "PGN file", file_name: "game1.pgn", content_type: "application/x-chess-pgn", data: "PGN DATA", rating_list_id: 1 },
          { comment: "PDF report", file_name: "report1.pdf", content_type: "application/pdf", data: "PDF DATA", rating_list_id: 2 },
          { comment: "Spreadsheet", file_name: "results.xlsx", content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", data: "XLSX DATA", rating_list_id: 3 },
          { comment: "Image", file_name: "photo.jpg", content_type: "image/jpeg", data: "JPEG DATA", rating_list_id: 4 },
          { comment: "Text file", file_name: "notes.txt", content_type: "text/plain", data: "TXT DATA", rating_list_id: 5 }
        ])

        # Events
        Event.create!([
          { name: "Import Ratings", time: 120, report: "Imported successfully", success: true },
          { name: "Export Ratings", time: 90, report: "Exported successfully", success: true },
          { name: "Update Player", time: 30, report: "Player updated", success: true },
          { name: "Delete Tournament", time: 45, report: "Tournament deleted", success: false },
          { name: "Create Article", time: 20, report: "Article created", success: true }
        ])

        # Failures
        Failure.create!([
          { name: "Import Error", details: "File format not supported" },
          { name: "Login Error", details: "Invalid password" },
          { name: "Rating Calculation Error", details: "Division by zero" },
          { name: "Tournament Error", details: "Missing rounds" },
          { name: "Subscription Error", details: "Payment failed" }
        ])

        # Fees
        Fee.create!([
          { description: "Annual Membership", status: "paid", category: "MEM", date: "2023-01-01", icu_id: 1, used: true },
          { description: "Tournament Entry", status: "unpaid", category: "TRN", date: "2023-02-01", icu_id: 2, used: false },
          { description: "Late Fee", status: "paid", category: "LFE", date: "2023-03-01", icu_id: 3, used: true },
          { description: "Replacement Card", status: "unpaid", category: "REP", date: "2023-04-01", icu_id: 4, used: false },
          { description: "Other Fee", status: "paid", category: "OTH", date: "2023-05-01", icu_id: 5, used: true }
        ])

        # # FidePlayerFiles
        # FidePlayerFile.create!([
        #   { description: "FIDE import Jan", players_in_file: 10, new_fide_records: 2, new_icu_mappings: 1, user_id: 1 },
        #   { description: "FIDE import Feb", players_in_file: 12, new_fide_records: 3, new_icu_mappings: 2, user_id: 2 },
        #   { description: "FIDE import Mar", players_in_file: 8, new_fide_records: 1, new_icu_mappings: 1, user_id: 3 },
        #   { description: "FIDE import Apr", players_in_file: 15, new_fide_records: 4, new_icu_mappings: 3, user_id: 4 },
        #   { description: "FIDE import May", players_in_file: 9, new_fide_records: 2, new_icu_mappings: 1, user_id: 5 }
        # ])

        # FidePlayers
        FidePlayer.create!([
          { last_name: "Magnus", first_name: "Carlsen", fed: "NOR", title: "GM", gender: "M", born: 1990, rating: 2850, icu_id: 1 },
          { last_name: "Nakamura", first_name: "Hikaru", fed: "USA", title: "GM", gender: "M", born: 1987, rating: 2780, icu_id: 2 },
          { last_name: "Hou", first_name: "Yifan", fed: "CHN", title: "GM", gender: "F", born: 1994, rating: 2650, icu_id: 3 },
          { last_name: "Ding", first_name: "Liren", fed: "CHN", title: "GM", gender: "M", born: 1992, rating: 2800, icu_id: 4 },
          { last_name: "Giri", first_name: "Anish", fed: "NED", title: "GM", gender: "M", born: 1994, rating: 2770, icu_id: 5 }
        ])

        # FideRatings
        FideRating.create!([
          { fide_id: 1, rating: 2850, games: 10, list: "2023-01-01" },
          { fide_id: 2, rating: 2780, games: 12, list: "2023-01-01" },
          { fide_id: 3, rating: 2650, games: 8, list: "2023-01-01" },
          { fide_id: 4, rating: 2800, games: 15, list: "2023-01-01" },
          { fide_id: 5, rating: 2770, games: 9, list: "2023-01-01" }
        ])

        # ICU Players
        IcuPlayer.create!([
          { first_name: "Alice", last_name: "Smith", email: "alice@example.com", club: "Dublin", fed: "IRL", title: "WFM", gender: "F", dob: "1990-01-01", joined: "2010-01-01", deceased: false },
          { first_name: "Bob", last_name: "Jones", email: "bob@example.com", club: "Cork", fed: "IRL", title: "FM", gender: "M", dob: "1985-05-05", joined: "2005-05-05", deceased: false },
          { first_name: "Carol", last_name: "Taylor", email: "carol@example.com", club: "Galway", fed: "IRL", title: "IM", gender: "F", dob: "1992-03-03", joined: "2012-03-03", deceased: true },
          { first_name: "Dave", last_name: "Brown", email: "dave@example.com", club: "Limerick", fed: "IRL", title: "GM", gender: "M", dob: "1980-07-07", joined: "2000-07-07", deceased: true },
          { first_name: "Eve", last_name: "Wilson", email: "eve@example.com", club: "Waterford", fed: "IRL", title: "CM", gender: "F", dob: "1995-09-09", joined: "2015-09-09", deceased: false },
          { first_name: "Frank", last_name: "Murphy", email: "frank@example.com", club: "Kilkenny", fed: "IRL", title: "FM", gender: "M", dob: "1988-11-11", joined: "2008-11-11", deceased: false },
          { first_name: "Grace", last_name: "O'Connor", email: "grace@example.com", club: "Sligo", fed: "IRL", title: "WIM", gender: "F", dob: "1993-06-15", joined: "2013-06-15", deceased: false },
          { first_name: "Henry", last_name: "Kelly", email: "henry@example.com", club: "Drogheda", fed: "IRL", title: "IM", gender: "M", dob: "1982-02-20", joined: "2002-02-20", deceased: true },
          { first_name: "Ivy", last_name: "Walsh", email: "ivy@example.com", club: "Athlone", fed: "IRL", title: "WCM", gender: "F", dob: "1997-08-08", joined: "2017-08-08", deceased: false },
          { first_name: "Jack", last_name: "Fitzgerald", email: "jack@example.com", club: "Tralee", fed: "IRL", title: "CM", gender: "M", dob: "1991-12-12", joined: "2011-12-12", deceased: true }
        ])

        # ICU Ratings
        IcuRating.create!([
          { list: "2023-01-01", icu_id: 1, rating: 1800, full: true },
          { list: "2023-01-01", icu_id: 2, rating: 2000, full: true },
          { list: "2023-01-01", icu_id: 3, rating: 2100, full: true },
          { list: "2023-01-01", icu_id: 4, rating: 2200, full: true },
          { list: "2023-01-01", icu_id: 5, rating: 1700, full: true }
        ])

        # LiveRatings
        LiveRating.create!([
          { icu_id: 1, rating: 1800, games: 10, full: true, last_rating: 1750, last_full: false },
          { icu_id: 2, rating: 2000, games: 12, full: true, last_rating: 1950, last_full: false },
          { icu_id: 3, rating: 2100, games: 8, full: true, last_rating: 2050, last_full: false },
          { icu_id: 4, rating: 2200, games: 15, full: true, last_rating: 2150, last_full: false },
          { icu_id: 5, rating: 1700, games: 9, full: true, last_rating: 1650, last_full: false }
        ])

        # Logins
        Login.create!([
          { user_id: 1, ip: "192.168.1.1", problem: "none", role: "admin" },
          { user_id: 2, ip: "192.168.1.2", problem: "none", role: "member" },
          { user_id: 3, ip: "192.168.1.3", problem: "none", role: "member" },
          { user_id: 4, ip: "192.168.1.4", problem: "none", role: "member" },
          { user_id: 5, ip: "192.168.1.5", problem: "none", role: "member" }
        ])

        # Players
        Player.create!([
          { first_name: "Alice", last_name: "Smith", original_name: "Alice Smith", fed: "IRL", title: "WFM", gender: "F", icu_id: 1, tournament_id: 1, icu_rating: 1800, num: 1 },
          { first_name: "Bob", last_name: "Jones", original_name: "Bob Jones", fed: "IRL", title: "FM", gender: "M", icu_id: 2, tournament_id: 2, icu_rating: 2000, num: 2 },
          { first_name: "Carol", last_name: "Taylor", original_name: "Carol Taylor", fed: "IRL", title: "IM", gender: "F", icu_id: 3, tournament_id: 3, icu_rating: 2100, num: 3 },
          { first_name: "Dave", last_name: "Brown", original_name: "Dave Brown", fed: "IRL", title: "GM", gender: "M", icu_id: 4, tournament_id: 4, icu_rating: 2200, num: 4 },
          { first_name: "Eve", last_name: "Wilson", original_name: "Eve Wilson", fed: "IRL", title: "CM", gender: "F", icu_id: 5, tournament_id: 5, icu_rating: 1700, num: 5 }
        ])

        # Publications
        Publication.create!([
          { rating_list_id: 1, last_tournament_id: 1, report: "Published list 1", total: 100, creates: 10, remains: 80, updates: 5, deletes: 5, notes: "First publication" },
          { rating_list_id: 2, last_tournament_id: 2, report: "Published list 2", total: 120, creates: 15, remains: 90, updates: 10, deletes: 5, notes: "Second publication" },
          { rating_list_id: 3, last_tournament_id: 3, report: "Published list 3", total: 110, creates: 12, remains: 85, updates: 8, deletes: 5, notes: "Third publication" },
          { rating_list_id: 4, last_tournament_id: 4, report: "Published list 4", total: 130, creates: 18, remains: 100, updates: 7, deletes: 5, notes: "Fourth publication" },
          { rating_list_id: 5, last_tournament_id: 5, report: "Published list 5", total: 90, creates: 8, remains: 70, updates: 7, deletes: 5, notes: "Fifth publication" }
        ])

        # RatingLists
        RatingList.create!([
          { date: "2022-01-01", tournament_cut_off: "2022-01-01", payment_cut_off: "2022-01-15" },
          { date: "2023-02-01", tournament_cut_off: "2023-02-01", payment_cut_off: "2023-02-15" },
          { date: "2023-03-01", tournament_cut_off: "2023-03-01", payment_cut_off: "2023-03-15" },
          { date: "2023-04-01", tournament_cut_off: "2023-04-01", payment_cut_off: "2023-04-15" },
          { date: "2023-05-01", tournament_cut_off: "2023-05-01", payment_cut_off: "2023-05-15" }
        ])

        # RatingRuns
        RatingRun.create!([
          { user_id: 1, status: "completed", report: "Run 1 completed", start_tournament_id: 1, last_tournament_id: 1, start_tournament_rorder: 1, last_tournament_rorder: 1, start_tournament_name: "Irish Open", last_tournament_name: "Irish Open", reason: "Monthly update" },
          { user_id: 2, status: "completed", report: "Run 2 completed", start_tournament_id: 2, last_tournament_id: 2, start_tournament_rorder: 2, last_tournament_rorder: 2, start_tournament_name: "Munster Championship", last_tournament_name: "Munster Championship", reason: "Monthly update" },
          { user_id: 3, status: "completed", report: "Run 3 completed", start_tournament_id: 3, last_tournament_id: 3, start_tournament_rorder: 3, last_tournament_rorder: 3, start_tournament_name: "Connacht Classic", last_tournament_name: "Connacht Classic", reason: "Monthly update" },
          { user_id: 4, status: "completed", report: "Run 4 completed", start_tournament_id: 4, last_tournament_id: 4, start_tournament_rorder: 4, last_tournament_rorder: 4, start_tournament_name: "Leinster League", last_tournament_name: "Leinster League", reason: "Monthly update" },
          { user_id: 5, status: "completed", report: "Run 5 completed", start_tournament_id: 5, last_tournament_id: 5, start_tournament_rorder: 5, last_tournament_rorder: 5, start_tournament_name: "Ulster Cup", last_tournament_name: "Ulster Cup", reason: "Monthly update" }
        ])

        # Results
        Result.create!([
          { round: 1, player_id: 1, opponent_id: 2, result: "W", colour: "W", rateable: true, expected_score: 0.6, rating_change: 10 },
          { round: 1, player_id: 2, opponent_id: 3, result: "L", colour: "B", rateable: true, expected_score: 0.4, rating_change: -8 },
          { round: 1, player_id: 3, opponent_id: 4, result: "D", colour: "W", rateable: true, expected_score: 0.5, rating_change: 0 },
          { round: 1, player_id: 4, opponent_id: 5, result: "W", colour: "B", rateable: true, expected_score: 0.7, rating_change: 12 },
          { round: 1, player_id: 5, opponent_id: 1, result: "L", colour: "W", rateable: true, expected_score: 0.3, rating_change: -6 }
        ])

        # Subscriptions
        Subscription.create!([
          { icu_id: 1, season: "2023-24", category: %w(online offline lifetime).sample, pay_date: "2023-01-01" },
          { icu_id: 2, season: "2023-24", category: %w(online offline lifetime).sample, pay_date: "2023-02-01" },
          { icu_id: 3, season: "2023-24", category: %w(online offline lifetime).sample, pay_date: "2023-03-01" },
          { icu_id: 4, season: "2023-24", category: %w(online offline lifetime).sample, pay_date: "2023-04-01" },
          { icu_id: 5, season: "2023-24", category: %w(online offline lifetime).sample, pay_date: "2023-05-01" }
        ])

        # Tournaments
        Tournament.create!([
          { name: "Irish Open", city: "Dublin", site: "Hotel", arbiter: "John Doe", start: "2023-01-10", finish: "2025-01-15", fed: "IRL", rounds: 5, user_id: 1 },
          { name: "Munster Championship", city: "Cork", site: "Community Center", arbiter: "Jane Roe", start: "2023-02-10", finish: "2023-02-12", fed: "IRL", rounds: 3, user_id: 2 },
          { name: "Connacht Classic", city: "Galway", site: "School", arbiter: "Jim Poe", start: "2023-03-05", finish: "2023-03-07", fed: "IRL", rounds: 3, user_id: 3 },
          { name: "Leinster League", city: "Limerick", site: "Hall", arbiter: "Jill Moe", start: "2023-04-01", finish: "2025-04-03", fed: "IRL", rounds: 3, user_id: 4 },
          { name: "Ulster Cup", city: "Belfast", site: "Arena", arbiter: "Jack Noe", start: "2023-05-10", finish: "2023-05-12", fed: "IRL", rounds: 3, user_id: 5 }
        ])

        # # Uploads
        # Upload.create!([
        #   { name: "Tournament PGN", format: "PGN", content_type: "application/x-chess-pgn", file_type: "pgn", size: 1024, tournament_id: 1, user_id: 1 },
        #   { name: "Tournament PDF", format: "PDF", content_type: "application/pdf", file_type: "pdf", size: 2048, tournament_id: 2, user_id: 2 },
        #   { name: "Tournament XLSX", format: "XLSX", content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", file_type: "xlsx", size: 3072, tournament_id: 3, user_id: 3 },
        #   { name: "Tournament JPG", format: "JPG", content_type: "image/jpeg", file_type: "jpg", size: 4096, tournament_id: 4, user_id: 4 },
        #   { name: "Tournament TXT", format: "TXT", content_type: "text/plain", file_type: "txt", size: 512, tournament_id: 5, user_id: 5 }
        # ])

        admin_player = IcuPlayer.create!(
            first_name: "Admin",
            last_name: "Admin",
            email: "admin@icu.ie",
            gender: Player::GENDERS.sample,
            dob: "2000-01-01",
            joined: "2020-01-01",
            deceased: false,
            club: "Dublin", 
            fed: "IRL", 
            title: "FM"
        )
        
        admin_user = User.create!(
            email: "admin@icu.ie",
            preferred_email: "admin@icu.ie",
            role: "admin",
            password: "password0",
            status: "ok",
            expiry: "2035-01-01",
            icu_id: admin_player.id
        )
    end
end
