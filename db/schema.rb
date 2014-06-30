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

ActiveRecord::Schema.define(version: 20140630135800) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "players", force: true do |t|
    t.string   "name"
    t.string   "position"
    t.integer  "riot_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "team_id"
    t.integer  "tier"
  end

  create_table "season_totals", force: true do |t|
    t.integer  "player_id"
    t.integer  "total_kills"
    t.integer  "total_deaths"
    t.integer  "total_assists"
    t.integer  "total_cs"
    t.integer  "total_triple_kill"
    t.integer  "total_quadra_kill"
    t.integer  "total_penta_kill"
    t.integer  "total_ten_ka"
    t.integer  "total_win"
    t.integer  "total_baron"
    t.integer  "total_dragon"
    t.integer  "total_first_blood"
    t.integer  "total_tower"
    t.integer  "total_time"
    t.float    "total_points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "variance"
    t.float    "ppg"
  end

  create_table "statlines", force: true do |t|
    t.integer  "player_id"
    t.string   "season"
    t.datetime "date"
    t.integer  "week"
    t.integer  "game"
    t.integer  "kills"
    t.integer  "deaths"
    t.integer  "assists"
    t.integer  "cs"
    t.integer  "triple_kill"
    t.integer  "quadra_kill"
    t.integer  "penta_kill"
    t.integer  "ten_ka"
    t.integer  "win"
    t.integer  "baron"
    t.integer  "dragon"
    t.integer  "first_blood"
    t.integer  "tower"
    t.integer  "time"
    t.float    "points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "opponent_id"
    t.integer  "match"
    t.integer  "double_kill"
  end

end
