# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160324002845) do

  create_table "articles", force: :cascade do |t|
    t.string   "headline",   limit: 255
    t.text     "story",      limit: 65535
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "published",                default: false
    t.string   "identity",   limit: 255
  end

  add_index "articles", ["published"], name: "index_articles_on_published", using: :btree
  add_index "articles", ["user_id"], name: "index_articles_on_user_id", using: :btree

  create_table "downloads", force: :cascade do |t|
    t.string   "comment",        limit: 255
    t.string   "file_name",      limit: 255
    t.string   "content_type",   limit: 255
    t.binary   "data",           limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rating_list_id", limit: 4
  end

  create_table "events", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "time",       limit: 2
    t.text     "report",     limit: 65535
    t.boolean  "success"
    t.datetime "created_at"
  end

  create_table "failures", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.text     "details",    limit: 65535
    t.datetime "created_at"
  end

  create_table "fees", force: :cascade do |t|
    t.string   "description", limit: 255
    t.string   "status",      limit: 25
    t.string   "category",    limit: 3
    t.date     "date"
    t.integer  "icu_id",      limit: 4
    t.boolean  "used",                    default: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  create_table "fide_player_files", force: :cascade do |t|
    t.text     "description",      limit: 65535
    t.integer  "players_in_file",  limit: 2,     default: 0
    t.integer  "new_fide_records", limit: 1,     default: 0
    t.integer  "new_icu_mappings", limit: 1,     default: 0
    t.integer  "user_id",          limit: 4
    t.datetime "created_at"
  end

  create_table "fide_players", force: :cascade do |t|
    t.string   "last_name",  limit: 255
    t.string   "first_name", limit: 255
    t.string   "fed",        limit: 3
    t.string   "title",      limit: 3
    t.string   "gender",     limit: 1
    t.integer  "born",       limit: 2
    t.integer  "rating",     limit: 2
    t.integer  "icu_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fide_players", ["icu_id"], name: "index_fide_players_on_icu_id", using: :btree
  add_index "fide_players", ["last_name", "first_name"], name: "index_fide_players_on_last_name_and_first_name", using: :btree

  create_table "fide_ratings", force: :cascade do |t|
    t.integer  "fide_id",    limit: 4
    t.integer  "rating",     limit: 2
    t.integer  "games",      limit: 2
    t.date     "list"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fide_ratings", ["fide_id"], name: "index_fide_ratings_on_fide_id", using: :btree
  add_index "fide_ratings", ["list"], name: "index_fide_ratings_on_list", using: :btree

  create_table "icu_players", force: :cascade do |t|
    t.string   "first_name",    limit: 255
    t.string   "last_name",     limit: 255
    t.string   "email",         limit: 255
    t.string   "club",          limit: 255
    t.string   "address",       limit: 255
    t.string   "phone_numbers", limit: 255
    t.string   "fed",           limit: 3
    t.string   "title",         limit: 3
    t.string   "gender",        limit: 1
    t.text     "note",          limit: 65535
    t.date     "dob"
    t.date     "joined"
    t.boolean  "deceased"
    t.integer  "master_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "icu_players", ["last_name", "first_name"], name: "index_icu_players_on_last_name_and_first_name", using: :btree

  create_table "icu_ratings", force: :cascade do |t|
    t.date    "list"
    t.integer "icu_id",          limit: 4
    t.integer "rating",          limit: 2
    t.boolean "full",                      default: false
    t.integer "original_rating", limit: 2
    t.boolean "original_full"
  end

  add_index "icu_ratings", ["icu_id"], name: "index_icu_ratings_on_icu_id", using: :btree
  add_index "icu_ratings", ["list", "icu_id"], name: "index_icu_ratings_on_list_and_icu_id", unique: true, using: :btree
  add_index "icu_ratings", ["list"], name: "index_icu_ratings_on_list", using: :btree

  create_table "live_ratings", force: :cascade do |t|
    t.integer "icu_id",      limit: 4
    t.integer "rating",      limit: 2
    t.integer "games",       limit: 2
    t.boolean "full",                  default: false
    t.integer "last_rating", limit: 2
    t.boolean "last_full",             default: false
  end

  add_index "live_ratings", ["icu_id"], name: "index_live_ratings_on_icu_id", unique: true, using: :btree

  create_table "logins", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "ip",         limit: 39
    t.string   "problem",    limit: 8,  default: "none"
    t.string   "role",       limit: 20
    t.datetime "created_at"
  end

  create_table "old_rating_histories", force: :cascade do |t|
    t.integer "old_tournament_id",  limit: 4
    t.integer "icu_player_id",      limit: 4
    t.integer "old_rating",         limit: 2
    t.integer "new_rating",         limit: 2
    t.integer "performance_rating", limit: 2
    t.integer "tournament_rating",  limit: 2
    t.integer "bonus",              limit: 2
    t.integer "games",              limit: 1
    t.integer "kfactor",            limit: 1
    t.decimal "actual_score",                 precision: 3, scale: 1
    t.decimal "expected_score",               precision: 8, scale: 6
  end

  add_index "old_rating_histories", ["icu_player_id"], name: "index_old_rating_histories_on_icu_player_id", using: :btree
  add_index "old_rating_histories", ["old_tournament_id", "icu_player_id"], name: "by_icu_player_old_tournament", unique: true, using: :btree
  add_index "old_rating_histories", ["old_tournament_id"], name: "index_old_rating_histories_on_old_tournament_id", using: :btree

  create_table "old_ratings", force: :cascade do |t|
    t.integer "icu_id", limit: 4
    t.integer "rating", limit: 2
    t.integer "games",  limit: 2
    t.boolean "full",             default: false
  end

  add_index "old_ratings", ["icu_id"], name: "index_old_ratings_on_icu_id", unique: true, using: :btree

  create_table "old_tournaments", force: :cascade do |t|
    t.string  "name",         limit: 255
    t.date    "date"
    t.integer "player_count", limit: 2
  end

  create_table "players", force: :cascade do |t|
    t.string   "first_name",            limit: 255
    t.string   "last_name",             limit: 255
    t.string   "fed",                   limit: 3
    t.string   "title",                 limit: 3
    t.string   "gender",                limit: 1
    t.integer  "icu_id",                limit: 4
    t.integer  "fide_id",               limit: 4
    t.integer  "icu_rating",            limit: 2
    t.integer  "fide_rating",           limit: 2
    t.date     "dob"
    t.string   "status",                limit: 255
    t.string   "category",              limit: 255
    t.integer  "rank",                  limit: 2
    t.integer  "num",                   limit: 4
    t.integer  "tournament_id",         limit: 4
    t.string   "original_name",         limit: 255
    t.string   "original_fed",          limit: 3
    t.string   "original_title",        limit: 3
    t.string   "original_gender",       limit: 1
    t.integer  "original_icu_id",       limit: 4
    t.integer  "original_fide_id",      limit: 4
    t.integer  "original_icu_rating",   limit: 2
    t.integer  "original_fide_rating",  limit: 2
    t.date     "original_dob"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "old_rating",            limit: 2
    t.integer  "new_rating",            limit: 2
    t.integer  "trn_rating",            limit: 2
    t.integer  "old_games",             limit: 2
    t.integer  "new_games",             limit: 2
    t.integer  "bonus",                 limit: 2
    t.integer  "k_factor",              limit: 1
    t.integer  "last_player_id",        limit: 4
    t.decimal  "actual_score",                      precision: 3, scale: 1
    t.decimal  "expected_score",                    precision: 8, scale: 6
    t.string   "last_signature",        limit: 255
    t.string   "curr_signature",        limit: 255
    t.boolean  "old_full",                                                  default: false
    t.boolean  "new_full",                                                  default: false
    t.boolean  "unrateable",                                                default: false
    t.integer  "rating_change",         limit: 2,                           default: 0
    t.integer  "pre_bonus_rating",      limit: 2
    t.integer  "pre_bonus_performance", limit: 2
  end

  add_index "players", ["fide_id"], name: "index_players_on_fide_id", using: :btree
  add_index "players", ["icu_id"], name: "index_players_on_icu_id", using: :btree
  add_index "players", ["rating_change"], name: "index_players_on_rating_change", using: :btree
  add_index "players", ["tournament_id"], name: "index_players_on_tournament_id", using: :btree

  create_table "publications", force: :cascade do |t|
    t.integer  "rating_list_id",     limit: 4
    t.integer  "last_tournament_id", limit: 4
    t.text     "report",             limit: 65535
    t.datetime "created_at"
    t.integer  "total",              limit: 3
    t.integer  "creates",            limit: 3
    t.integer  "remains",            limit: 3
    t.integer  "updates",            limit: 3
    t.integer  "deletes",            limit: 3
    t.text     "notes",              limit: 65535
  end

  add_index "publications", ["rating_list_id"], name: "index_publications_on_rating_list_id", using: :btree

  create_table "rating_lists", force: :cascade do |t|
    t.date     "date"
    t.date     "tournament_cut_off"
    t.datetime "created_at"
    t.date     "payment_cut_off"
  end

  add_index "rating_lists", ["date"], name: "index_rating_lists_on_date", using: :btree

  create_table "rating_runs", force: :cascade do |t|
    t.integer  "user_id",                 limit: 4
    t.string   "status",                  limit: 255
    t.text     "report",                  limit: 65535
    t.integer  "start_tournament_id",     limit: 4
    t.integer  "last_tournament_id",      limit: 4
    t.integer  "start_tournament_rorder", limit: 4
    t.integer  "last_tournament_rorder",  limit: 4
    t.string   "start_tournament_name",   limit: 255
    t.string   "last_tournament_name",    limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "reason",                  limit: 100,   default: "", null: false
  end

  create_table "results", force: :cascade do |t|
    t.integer  "round",          limit: 1
    t.integer  "player_id",      limit: 4
    t.integer  "opponent_id",    limit: 4
    t.string   "result",         limit: 1
    t.string   "colour",         limit: 1
    t.boolean  "rateable"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "expected_score",           precision: 8, scale: 6
    t.decimal  "rating_change",            precision: 8, scale: 6
  end

  add_index "results", ["opponent_id"], name: "index_results_on_opponent_id", using: :btree
  add_index "results", ["player_id"], name: "index_results_on_player_id", using: :btree
  add_index "results", ["rating_change"], name: "index_results_on_rating_change", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "icu_id",     limit: 4
    t.string   "season",     limit: 7
    t.string   "category",   limit: 8
    t.date     "pay_date"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "subscriptions", ["category"], name: "index_subscriptions_on_category", using: :btree
  add_index "subscriptions", ["icu_id"], name: "index_subscriptions_on_icu_id", using: :btree
  add_index "subscriptions", ["season"], name: "index_subscriptions_on_season", using: :btree

  create_table "tournaments", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "city",                   limit: 255
    t.string   "site",                   limit: 255
    t.string   "arbiter",                limit: 255
    t.string   "deputy",                 limit: 255
    t.string   "tie_breaks",             limit: 255
    t.string   "time_control",           limit: 255
    t.date     "start"
    t.date     "finish"
    t.string   "fed",                    limit: 3
    t.integer  "rounds",                 limit: 1
    t.integer  "user_id",                limit: 4
    t.string   "original_name",          limit: 255
    t.string   "original_tie_breaks",    limit: 255
    t.date     "original_start"
    t.date     "original_finish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",                 limit: 255,   default: "ok"
    t.string   "stage",                  limit: 20,    default: "initial"
    t.integer  "rorder",                 limit: 4
    t.integer  "reratings",              limit: 2,     default: 0
    t.integer  "next_tournament_id",     limit: 4
    t.integer  "last_tournament_id",     limit: 4
    t.integer  "old_last_tournament_id", limit: 4
    t.datetime "first_rated"
    t.datetime "last_rated"
    t.integer  "last_rated_msec",        limit: 2
    t.string   "last_signature",         limit: 32
    t.string   "curr_signature",         limit: 32
    t.boolean  "locked",                               default: false
    t.text     "notes",                  limit: 65535
    t.integer  "fide_id",                limit: 4
    t.integer  "iterations1",            limit: 2,     default: 0
    t.integer  "iterations2",            limit: 2,     default: 0
    t.boolean  "rerate",                               default: false
  end

  add_index "tournaments", ["curr_signature"], name: "index_tournaments_on_curr_signature", using: :btree
  add_index "tournaments", ["last_rated"], name: "index_tournaments_on_last_rated", using: :btree
  add_index "tournaments", ["last_rated_msec"], name: "index_tournaments_on_last_rated_msec", using: :btree
  add_index "tournaments", ["last_signature"], name: "index_tournaments_on_last_signature", using: :btree
  add_index "tournaments", ["last_tournament_id"], name: "index_tournaments_on_last_tournament_id", using: :btree
  add_index "tournaments", ["old_last_tournament_id"], name: "index_tournaments_on_old_last_tournament_id", using: :btree
  add_index "tournaments", ["rorder"], name: "index_tournaments_on_rorder", unique: true, using: :btree
  add_index "tournaments", ["stage"], name: "index_tournaments_on_stage", using: :btree
  add_index "tournaments", ["user_id"], name: "index_tournaments_on_user_id", using: :btree

  create_table "uploads", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "format",        limit: 255
    t.string   "content_type",  limit: 255
    t.string   "file_type",     limit: 255
    t.integer  "size",          limit: 4
    t.integer  "tournament_id", limit: 4
    t.integer  "user_id",       limit: 4
    t.text     "error",         limit: 65535
    t.datetime "created_at"
  end

  add_index "uploads", ["tournament_id"], name: "index_uploads_on_tournament_id", using: :btree
  add_index "uploads", ["user_id"], name: "index_uploads_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",           limit: 50
    t.string   "preferred_email", limit: 50
    t.string   "password",        limit: 32
    t.string   "role",            limit: 20,  default: "member"
    t.integer  "icu_id",          limit: 4
    t.date     "expiry"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salt",            limit: 32
    t.string   "status",          limit: 20,  default: "ok"
    t.datetime "last_pulled_at"
    t.string   "last_pull",       limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

end
