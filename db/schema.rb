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

ActiveRecord::Schema.define(version: 20210611204425) do

  create_table "articles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "headline"
    t.text     "story",      limit: 65535
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "published",                default: false
    t.string   "identity"
    t.index ["published"], name: "index_articles_on_published", using: :btree
    t.index ["user_id"], name: "index_articles_on_user_id", using: :btree
  end

  create_table "downloads", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "comment"
    t.string   "file_name"
    t.string   "content_type"
    t.binary   "data",           limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rating_list_id"
  end

  create_table "events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "time",       limit: 2
    t.text     "report",     limit: 65535
    t.boolean  "success"
    t.datetime "created_at"
  end

  create_table "failures", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.text     "details",    limit: 65535
    t.datetime "created_at"
  end

  create_table "fees", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "description"
    t.string   "status",      limit: 25
    t.string   "category",    limit: 3
    t.date     "date"
    t.integer  "icu_id"
    t.boolean  "used",                   default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  create_table "fide_player_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "description",      limit: 65535
    t.integer  "players_in_file",  limit: 2,     default: 0
    t.integer  "new_fide_records", limit: 1,     default: 0
    t.integer  "new_icu_mappings", limit: 1,     default: 0
    t.integer  "user_id"
    t.datetime "created_at"
  end

  create_table "fide_players", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "last_name"
    t.string   "first_name"
    t.string   "fed",        limit: 3
    t.string   "title",      limit: 3
    t.string   "gender",     limit: 1
    t.integer  "born",       limit: 2
    t.integer  "rating",     limit: 2
    t.integer  "icu_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["icu_id"], name: "index_fide_players_on_icu_id", using: :btree
    t.index ["last_name", "first_name"], name: "index_fide_players_on_last_name_and_first_name", using: :btree
  end

  create_table "fide_ratings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "fide_id"
    t.integer  "rating",     limit: 2
    t.integer  "games",      limit: 2
    t.date     "list"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["fide_id"], name: "index_fide_ratings_on_fide_id", using: :btree
    t.index ["list"], name: "index_fide_ratings_on_list", using: :btree
  end

  create_table "icu_players", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "club"
    t.string   "address"
    t.string   "phone_numbers"
    t.string   "fed",           limit: 3
    t.string   "title",         limit: 3
    t.string   "gender",        limit: 1
    t.text     "note",          limit: 65535
    t.date     "dob"
    t.date     "joined"
    t.boolean  "deceased"
    t.integer  "master_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["last_name", "first_name"], name: "index_icu_players_on_last_name_and_first_name", using: :btree
  end

  create_table "icu_ratings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.date    "list"
    t.integer "icu_id"
    t.integer "rating",          limit: 2
    t.boolean "full",                      default: false
    t.integer "original_rating", limit: 2
    t.boolean "original_full"
    t.index ["icu_id"], name: "index_icu_ratings_on_icu_id", using: :btree
    t.index ["list", "icu_id"], name: "index_icu_ratings_on_list_and_icu_id", unique: true, using: :btree
    t.index ["list"], name: "index_icu_ratings_on_list", using: :btree
  end

  create_table "live_ratings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "icu_id"
    t.integer "rating",      limit: 2
    t.integer "games",       limit: 2
    t.boolean "full",                  default: false
    t.integer "last_rating", limit: 2
    t.boolean "last_full",             default: false
    t.index ["icu_id"], name: "index_live_ratings_on_icu_id", unique: true, using: :btree
  end

  create_table "logins", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "ip",         limit: 39
    t.string   "problem",    limit: 8,  default: "none"
    t.string   "role",       limit: 20
    t.datetime "created_at"
  end

  create_table "old_rating_histories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "old_tournament_id"
    t.integer "icu_player_id"
    t.integer "old_rating",         limit: 2
    t.integer "new_rating",         limit: 2
    t.integer "performance_rating", limit: 2
    t.integer "tournament_rating",  limit: 2
    t.integer "bonus",              limit: 2
    t.integer "games",              limit: 1
    t.integer "kfactor",            limit: 1
    t.decimal "actual_score",                 precision: 3, scale: 1
    t.decimal "expected_score",               precision: 8, scale: 6
    t.index ["icu_player_id"], name: "index_old_rating_histories_on_icu_player_id", using: :btree
    t.index ["old_tournament_id", "icu_player_id"], name: "by_icu_player_old_tournament", unique: true, using: :btree
    t.index ["old_tournament_id"], name: "index_old_rating_histories_on_old_tournament_id", using: :btree
  end

  create_table "old_ratings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "icu_id"
    t.integer "rating", limit: 2
    t.integer "games",  limit: 2
    t.boolean "full",             default: false
    t.index ["icu_id"], name: "index_old_ratings_on_icu_id", unique: true, using: :btree
  end

  create_table "old_tournaments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "name"
    t.date    "date"
    t.integer "player_count", limit: 2
  end

  create_table "players", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "fed",                   limit: 3
    t.string   "title",                 limit: 3
    t.string   "gender",                limit: 1
    t.integer  "icu_id"
    t.integer  "fide_id"
    t.integer  "icu_rating",            limit: 2
    t.integer  "fide_rating",           limit: 2
    t.date     "dob"
    t.string   "status"
    t.string   "category"
    t.integer  "rank",                  limit: 2
    t.integer  "num"
    t.integer  "tournament_id"
    t.string   "original_name"
    t.string   "original_fed",          limit: 3
    t.string   "original_title",        limit: 3
    t.string   "original_gender",       limit: 1
    t.integer  "original_icu_id"
    t.integer  "original_fide_id"
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
    t.integer  "last_player_id"
    t.decimal  "actual_score",                    precision: 3, scale: 1
    t.decimal  "expected_score",                  precision: 8, scale: 6
    t.string   "last_signature"
    t.string   "curr_signature"
    t.boolean  "old_full",                                                default: false
    t.boolean  "new_full",                                                default: false
    t.boolean  "unrateable",                                              default: false
    t.integer  "rating_change",         limit: 2,                         default: 0
    t.integer  "pre_bonus_rating",      limit: 2
    t.integer  "pre_bonus_performance", limit: 2
    t.index ["fide_id"], name: "index_players_on_fide_id", using: :btree
    t.index ["icu_id"], name: "index_players_on_icu_id", using: :btree
    t.index ["rating_change"], name: "index_players_on_rating_change", using: :btree
    t.index ["tournament_id"], name: "index_players_on_tournament_id", using: :btree
  end

  create_table "publications", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "rating_list_id"
    t.integer  "last_tournament_id"
    t.text     "report",             limit: 65535
    t.datetime "created_at"
    t.integer  "total",              limit: 3
    t.integer  "creates",            limit: 3
    t.integer  "remains",            limit: 3
    t.integer  "updates",            limit: 3
    t.integer  "deletes",            limit: 3
    t.text     "notes",              limit: 65535
    t.index ["rating_list_id"], name: "index_publications_on_rating_list_id", using: :btree
  end

  create_table "rating_lists", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.date     "date"
    t.date     "tournament_cut_off"
    t.datetime "created_at"
    t.date     "payment_cut_off"
    t.index ["date"], name: "index_rating_lists_on_date", using: :btree
  end

  create_table "rating_runs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "status"
    t.text     "report",                  limit: 65535
    t.integer  "start_tournament_id"
    t.integer  "last_tournament_id"
    t.integer  "start_tournament_rorder"
    t.integer  "last_tournament_rorder"
    t.string   "start_tournament_name"
    t.string   "last_tournament_name"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "reason",                  limit: 100,   default: "", null: false
  end

  create_table "results", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "round",          limit: 1
    t.integer  "player_id"
    t.integer  "opponent_id"
    t.string   "result",         limit: 1
    t.string   "colour",         limit: 1
    t.boolean  "rateable"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "expected_score",           precision: 8, scale: 6
    t.decimal  "rating_change",            precision: 8, scale: 6
    t.index ["opponent_id"], name: "index_results_on_opponent_id", using: :btree
    t.index ["player_id"], name: "index_results_on_player_id", using: :btree
    t.index ["rating_change"], name: "index_results_on_rating_change", using: :btree
  end

  create_table "subscriptions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "icu_id"
    t.string   "season",     limit: 7
    t.string   "category",   limit: 8
    t.date     "pay_date"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["category"], name: "index_subscriptions_on_category", using: :btree
    t.index ["icu_id"], name: "index_subscriptions_on_icu_id", using: :btree
    t.index ["season"], name: "index_subscriptions_on_season", using: :btree
  end

  create_table "tournaments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "city"
    t.string   "site"
    t.string   "arbiter"
    t.string   "deputy"
    t.string   "tie_breaks"
    t.string   "time_control"
    t.date     "start"
    t.date     "finish"
    t.string   "fed",                    limit: 3
    t.integer  "rounds",                 limit: 1
    t.integer  "user_id"
    t.string   "original_name"
    t.string   "original_tie_breaks"
    t.date     "original_start"
    t.date     "original_finish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",                               default: "ok"
    t.string   "stage",                  limit: 20,    default: "initial"
    t.integer  "rorder"
    t.integer  "reratings",              limit: 2,     default: 0
    t.integer  "next_tournament_id"
    t.integer  "last_tournament_id"
    t.integer  "old_last_tournament_id"
    t.datetime "first_rated"
    t.integer  "first_rated_msec",       limit: 2,     default: 0
    t.datetime "last_rated"
    t.integer  "last_rated_msec",        limit: 2
    t.string   "last_signature",         limit: 32
    t.string   "curr_signature",         limit: 32
    t.boolean  "locked",                               default: false
    t.text     "notes",                  limit: 65535
    t.integer  "fide_id"
    t.integer  "iterations1",            limit: 2,     default: 0
    t.integer  "iterations2",            limit: 2,     default: 0
    t.boolean  "rerate",                               default: false
    t.index ["curr_signature"], name: "index_tournaments_on_curr_signature", using: :btree
    t.index ["last_rated"], name: "index_tournaments_on_last_rated", using: :btree
    t.index ["last_rated_msec"], name: "index_tournaments_on_last_rated_msec", using: :btree
    t.index ["last_signature"], name: "index_tournaments_on_last_signature", using: :btree
    t.index ["last_tournament_id"], name: "index_tournaments_on_last_tournament_id", using: :btree
    t.index ["old_last_tournament_id"], name: "index_tournaments_on_old_last_tournament_id", using: :btree
    t.index ["rorder"], name: "index_tournaments_on_rorder", unique: true, using: :btree
    t.index ["stage"], name: "index_tournaments_on_stage", using: :btree
    t.index ["user_id"], name: "index_tournaments_on_user_id", using: :btree
  end

  create_table "uploads", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "format"
    t.string   "content_type"
    t.string   "file_type"
    t.integer  "size"
    t.integer  "tournament_id"
    t.integer  "user_id"
    t.text     "error",         limit: 65535
    t.datetime "created_at"
    t.index ["tournament_id"], name: "index_uploads_on_tournament_id", using: :btree
    t.index ["user_id"], name: "index_uploads_on_user_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "email",           limit: 50
    t.string   "preferred_email", limit: 50
    t.string   "password",        limit: 32
    t.string   "role",            limit: 20, default: "member"
    t.integer  "icu_id"
    t.date     "expiry"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salt",            limit: 32
    t.string   "status",          limit: 20, default: "ok"
    t.datetime "last_pulled_at"
    t.string   "last_pull"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
  end

end
