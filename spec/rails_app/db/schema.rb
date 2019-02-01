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

ActiveRecord::Schema.define(version: 20190201160159) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", force: :cascade do |t|
    t.integer "course_id"
    t.boolean "published"
  end

  create_table "courses", force: :cascade do |t|
    t.string  "name"
    t.integer "user_id"
    t.integer "published_article_count", default: 0, null: false
  end

  create_table "messages", force: :cascade do |t|
    t.string  "body"
    t.integer "sent_message_count", default: 0, null: false
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "user_id"
    t.integer "net_charge_usd"
  end

  create_table "receipts", force: :cascade do |t|
    t.integer "message_id"
    t.string  "sent_at"
    t.string  "opened_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.integer  "courses_count",      default: 0, null: false
    t.integer  "transactions_gross", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
