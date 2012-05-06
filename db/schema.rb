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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120414021713) do

  create_table "action_groups", :force => true do |t|
    t.integer  "action_id"
    t.integer  "scene_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "action_groups", ["action_id", "scene_id"], :name => "index_action_groups_on_action_id_and_scene_id", :unique => true

  create_table "actions", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "asset_maps", :force => true do |t|
    t.integer "asset_id"
    t.string  "assetable_type"
    t.integer "assetable_id"
  end

  add_index "asset_maps", ["asset_id", "assetable_id"], :name => "index_asset_maps_on_asset_id_and_assetable_id", :unique => true
  add_index "asset_maps", ["asset_id"], :name => "index_asset_maps_on_asset_id"
  add_index "asset_maps", ["assetable_id"], :name => "index_asset_maps_on_assetable_id"

  create_table "assets", :force => true do |t|
    t.string   "type"
    t.string   "image"
    t.string   "video"
    t.string   "sound"
    t.string   "font"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "assets", ["type"], :name => "index_assets_on_type"

  create_table "attributes", :force => true do |t|
    t.integer  "action_id"
    t.string   "type"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "attributes", ["action_id"], :name => "index_attributes_on_action_id"

  create_table "keyframe_texts", :force => true do |t|
    t.integer  "keyframe_id"
    t.text     "content"
    t.string   "content_highlight_times"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "keyframe_texts", ["keyframe_id"], :name => "index_keyframe_texts_on_keyframe_id"

  create_table "keyframes", :force => true do |t|
    t.integer  "scene_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "keyframes", ["scene_id"], :name => "index_keyframes_on_scene_id"

  create_table "scene_attributes", :force => true do |t|
    t.string   "value"
    t.integer  "keyframe_id"
    t.integer  "attribute_id"
    t.integer  "action_group_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "scene_attributes", ["action_group_id"], :name => "index_scene_attributes_on_action_group_id"
  add_index "scene_attributes", ["attribute_id"], :name => "index_scene_attributes_on_attribute_id"
  add_index "scene_attributes", ["keyframe_id"], :name => "index_scene_attributes_on_keyframe_id"

  create_table "scenes", :force => true do |t|
    t.integer  "storybook_id"
    t.integer  "sound_id"
    t.integer  "image_id"
    t.integer  "page_number"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "scenes", ["storybook_id"], :name => "index_scenes_on_storybook_id"

  create_table "settings", :force => true do |t|
    t.string   "type"
    t.integer  "scene_id"
    t.integer  "storybook_id"
    t.integer  "font_id"
    t.integer  "font_size"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "settings", ["scene_id"], :name => "index_settings_on_scene_id"
  add_index "settings", ["storybook_id"], :name => "index_settings_on_storybook_id"

  create_table "storybooks", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "storybooks", ["user_id"], :name => "index_storybooks_on_user_id"

  create_table "touch_zones", :force => true do |t|
    t.integer  "scene_id"
    t.integer  "origin_x"
    t.integer  "origin_y"
    t.integer  "radius"
    t.integer  "video_id"
    t.integer  "sound_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "touch_zones", ["scene_id"], :name => "index_touch_zones_on_scene_id"

  create_table "users", :force => true do |t|
    t.string   "email",                                      :null => false
    t.string   "username"
    t.string   "role",                   :default => "user", :null => false
    t.string   "permalink"
    t.string   "password_digest",                            :null => false
    t.string   "auth_token"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end