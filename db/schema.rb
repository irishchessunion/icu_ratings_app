# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_05_03_162110) do

  create_table "articles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "headline"
    t.text "story"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "published", default: false
    t.string "identity"
    t.index ["published"], name: "index_articles_on_published"
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "downloads", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "comment"
    t.string "file_name"
    t.string "content_type"
    t.binary "data", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "rating_list_id"
  end

  create_table "events", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.integer "time", limit: 2
    t.text "report"
    t.boolean "success"
    t.datetime "created_at"
  end

  create_table "failures", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.text "details"
    t.datetime "created_at"
  end

  create_table "fees", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "description"
    t.string "status", limit: 25
    t.string "category", limit: 3
    t.date "date"
    t.integer "icu_id"
    t.boolean "used", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fide_player_files", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "description"
    t.integer "players_in_file", limit: 2, default: 0
    t.integer "new_fide_records", limit: 1, default: 0
    t.integer "new_icu_mappings", limit: 1, default: 0
    t.integer "user_id"
    t.datetime "created_at"
  end

  create_table "fide_players", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "last_name"
    t.string "first_name"
    t.string "fed", limit: 3
    t.string "title", limit: 3
    t.string "gender", limit: 1
    t.integer "born", limit: 2
    t.integer "rating", limit: 2
    t.integer "icu_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "rapid_rating"
    t.integer "blitz_rating"
    t.index ["icu_id"], name: "index_fide_players_on_icu_id"
    t.index ["last_name", "first_name"], name: "index_fide_players_on_last_name_and_first_name"
  end

  create_table "fide_ratings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "fide_id"
    t.integer "rating", limit: 2
    t.integer "games", limit: 2
    t.date "list"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["fide_id"], name: "index_fide_ratings_on_fide_id"
    t.index ["list"], name: "index_fide_ratings_on_list"
  end

  create_table "icu_players", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "club"
    t.string "address"
    t.string "phone_numbers"
    t.string "fed", limit: 3
    t.string "title", limit: 3
    t.string "gender", limit: 1
    t.text "note"
    t.date "dob"
    t.date "joined"
    t.boolean "deceased"
    t.integer "master_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["last_name", "first_name"], name: "index_icu_players_on_last_name_and_first_name"
  end

  create_table "icu_ratings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.date "list"
    t.integer "icu_id"
    t.integer "rating", limit: 2
    t.boolean "full", default: false
    t.integer "original_rating", limit: 2
    t.boolean "original_full"
    t.index ["icu_id"], name: "index_icu_ratings_on_icu_id"
    t.index ["list", "icu_id"], name: "index_icu_ratings_on_list_and_icu_id", unique: true
    t.index ["list"], name: "index_icu_ratings_on_list"
  end

  create_table "live_ratings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "icu_id"
    t.integer "rating", limit: 2
    t.integer "games", limit: 2
    t.boolean "full", default: false
    t.integer "last_rating", limit: 2
    t.boolean "last_full", default: false
    t.index ["icu_id"], name: "index_live_ratings_on_icu_id", unique: true
  end

  create_table "logins", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "ip", limit: 39
    t.string "problem", limit: 8, default: "none"
    t.string "role", limit: 20
    t.datetime "created_at"
  end

  create_table "old_rating_histories", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "old_tournament_id"
    t.integer "icu_player_id"
    t.integer "old_rating", limit: 2
    t.integer "new_rating", limit: 2
    t.integer "performance_rating", limit: 2
    t.integer "tournament_rating", limit: 2
    t.integer "bonus", limit: 2
    t.integer "games", limit: 1
    t.integer "kfactor", limit: 1
    t.decimal "actual_score", precision: 3, scale: 1
    t.decimal "expected_score", precision: 8, scale: 6
    t.index ["icu_player_id"], name: "index_old_rating_histories_on_icu_player_id"
    t.index ["old_tournament_id", "icu_player_id"], name: "by_icu_player_old_tournament", unique: true
    t.index ["old_tournament_id"], name: "index_old_rating_histories_on_old_tournament_id"
  end

  create_table "old_ratings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "icu_id"
    t.integer "rating", limit: 2
    t.integer "games", limit: 2
    t.boolean "full", default: false
    t.index ["icu_id"], name: "index_old_ratings_on_icu_id", unique: true
  end

  create_table "old_tournaments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.integer "player_count", limit: 2
  end

  create_table "players", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "fed", limit: 3
    t.string "title", limit: 3
    t.string "gender", limit: 1
    t.integer "icu_id"
    t.integer "fide_id"
    t.integer "icu_rating", limit: 2
    t.integer "fide_rating", limit: 2
    t.date "dob"
    t.string "status"
    t.string "category"
    t.integer "rank", limit: 2
    t.integer "num"
    t.integer "tournament_id"
    t.string "original_name"
    t.string "original_fed", limit: 3
    t.string "original_title", limit: 3
    t.string "original_gender", limit: 1
    t.integer "original_icu_id"
    t.integer "original_fide_id"
    t.integer "original_icu_rating", limit: 2
    t.integer "original_fide_rating", limit: 2
    t.date "original_dob"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "old_rating", limit: 2
    t.integer "new_rating", limit: 2
    t.integer "trn_rating", limit: 2
    t.integer "old_games", limit: 2
    t.integer "new_games", limit: 2
    t.integer "bonus", limit: 2
    t.integer "k_factor", limit: 1
    t.integer "last_player_id"
    t.decimal "actual_score", precision: 3, scale: 1
    t.decimal "expected_score", precision: 8, scale: 6
    t.string "last_signature"
    t.string "curr_signature"
    t.boolean "old_full", default: false
    t.boolean "new_full", default: false
    t.boolean "unrateable", default: false
    t.integer "rating_change", limit: 2, default: 0
    t.integer "pre_bonus_rating", limit: 2
    t.integer "pre_bonus_performance", limit: 2
    t.index ["fide_id"], name: "index_players_on_fide_id"
    t.index ["icu_id"], name: "index_players_on_icu_id"
    t.index ["rating_change"], name: "index_players_on_rating_change"
    t.index ["tournament_id"], name: "index_players_on_tournament_id"
  end

  create_table "publications", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "rating_list_id"
    t.integer "last_tournament_id"
    t.text "report"
    t.datetime "created_at"
    t.integer "total", limit: 3
    t.integer "creates", limit: 3
    t.integer "remains", limit: 3
    t.integer "updates", limit: 3
    t.integer "deletes", limit: 3
    t.text "notes"
    t.index ["rating_list_id"], name: "index_publications_on_rating_list_id"
  end

  create_table "rating_lists", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.date "date"
    t.date "tournament_cut_off"
    t.datetime "created_at"
    t.date "payment_cut_off"
    t.index ["date"], name: "index_rating_lists_on_date"
  end

  create_table "rating_runs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "status"
    t.text "report"
    t.integer "start_tournament_id"
    t.integer "last_tournament_id"
    t.integer "start_tournament_rorder"
    t.integer "last_tournament_rorder"
    t.string "start_tournament_name"
    t.string "last_tournament_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "reason", limit: 100, default: "", null: false
  end

  create_table "results", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "round", limit: 1
    t.integer "player_id"
    t.integer "opponent_id"
    t.string "result", limit: 1
    t.string "colour", limit: 1
    t.boolean "rateable"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal "expected_score", precision: 8, scale: 6
    t.decimal "rating_change", precision: 8, scale: 6
    t.index ["opponent_id"], name: "index_results_on_opponent_id"
    t.index ["player_id"], name: "index_results_on_player_id"
    t.index ["rating_change"], name: "index_results_on_rating_change"
  end

  create_table "subscriptions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "icu_id"
    t.string "season", limit: 7
    t.string "category", limit: 8
    t.date "pay_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["category"], name: "index_subscriptions_on_category"
    t.index ["icu_id"], name: "index_subscriptions_on_icu_id"
    t.index ["season"], name: "index_subscriptions_on_season"
  end

  create_table "tournaments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "city"
    t.string "site"
    t.string "arbiter"
    t.string "deputy"
    t.string "tie_breaks"
    t.string "time_control"
    t.date "start"
    t.date "finish"
    t.string "fed", limit: 3
    t.integer "rounds", limit: 1
    t.integer "user_id"
    t.string "original_name"
    t.string "original_tie_breaks"
    t.date "original_start"
    t.date "original_finish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "status", default: "ok"
    t.string "stage", limit: 20, default: "initial"
    t.integer "rorder"
    t.integer "reratings", limit: 2, default: 0
    t.integer "next_tournament_id"
    t.integer "last_tournament_id"
    t.integer "old_last_tournament_id"
    t.datetime "first_rated"
    t.datetime "last_rated"
    t.integer "last_rated_msec", limit: 2
    t.string "last_signature", limit: 32
    t.string "curr_signature", limit: 32
    t.boolean "locked", default: false
    t.text "notes"
    t.integer "fide_id"
    t.integer "iterations1", limit: 2, default: 0
    t.integer "iterations2", limit: 2, default: 0
    t.boolean "rerate", default: false
    t.integer "first_rated_msec", limit: 2, default: 0
    t.index ["curr_signature"], name: "index_tournaments_on_curr_signature"
    t.index ["last_rated"], name: "index_tournaments_on_last_rated"
    t.index ["last_rated_msec"], name: "index_tournaments_on_last_rated_msec"
    t.index ["last_signature"], name: "index_tournaments_on_last_signature"
    t.index ["last_tournament_id"], name: "index_tournaments_on_last_tournament_id"
    t.index ["old_last_tournament_id"], name: "index_tournaments_on_old_last_tournament_id"
    t.index ["rorder"], name: "index_tournaments_on_rorder", unique: true
    t.index ["stage"], name: "index_tournaments_on_stage"
    t.index ["user_id"], name: "index_tournaments_on_user_id"
  end

  create_table "uploads", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "format"
    t.string "content_type"
    t.string "file_type"
    t.integer "size"
    t.integer "tournament_id"
    t.integer "user_id"
    t.text "error"
    t.datetime "created_at"
    t.index ["tournament_id"], name: "index_uploads_on_tournament_id"
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", limit: 50
    t.string "preferred_email", limit: 50
    t.string "password", limit: 32
    t.string "role", limit: 20, default: "member"
    t.integer "icu_id"
    t.date "expiry"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "salt", limit: 32
    t.string "status", limit: 20, default: "ok"
    t.datetime "last_pulled_at"
    t.string "last_pull"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
