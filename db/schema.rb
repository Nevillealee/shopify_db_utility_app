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

ActiveRecord::Schema.define(version: 2018_08_15_221707) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alternate_products", force: :cascade do |t|
    t.string "product_title"
    t.string "product_id"
    t.string "variant_id"
    t.string "sku"
    t.string "product_collection"
    t.index ["product_id"], name: "index_alternate_products_on_product_id"
  end

  create_table "charge_billing_address", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "company"
    t.string "country"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "province"
    t.string "zip"
    t.string "charge_id"
    t.index ["charge_id"], name: "index_charge_billing_address_on_charge_id"
  end

  create_table "charge_client_details", force: :cascade do |t|
    t.string "charge_id"
    t.string "browser_ip"
    t.string "user_agent"
    t.index ["charge_id"], name: "index_charge_client_details_on_charge_id"
  end

  create_table "charge_fixed_line_items", force: :cascade do |t|
    t.string "charge_id"
    t.integer "grams"
    t.decimal "price", precision: 10, scale: 2
    t.integer "quantity"
    t.string "shopify_product_id"
    t.string "shopify_variant_id"
    t.string "sku"
    t.string "subscription_id"
    t.string "title"
    t.string "variant_title"
    t.string "vendor"
    t.index ["charge_id"], name: "index_charge_fixed_line_items_on_charge_id"
  end

  create_table "charge_variable_line_items", force: :cascade do |t|
    t.string "charge_id"
    t.string "name"
    t.string "value"
    t.index ["charge_id"], name: "index_charge_variable_line_items_on_charge_id"
  end

  create_table "charges", force: :cascade do |t|
    t.string "address_id"
    t.jsonb "billing_address"
    t.jsonb "client_details"
    t.datetime "created_at"
    t.string "customer_hash"
    t.string "customer_id"
    t.string "first_name"
    t.string "charge_id"
    t.string "last_name"
    t.jsonb "line_items"
    t.string "note"
    t.jsonb "note_attributes"
    t.datetime "processed_at"
    t.datetime "scheduled_at"
    t.integer "shipments_count"
    t.jsonb "shipping_address"
    t.string "shopify_order_id"
    t.string "status"
    t.decimal "sub_total", precision: 10, scale: 2
    t.decimal "sub_total_price", precision: 10, scale: 2
    t.string "tags"
    t.decimal "tax_lines", precision: 10, scale: 2
    t.decimal "total_discounts", precision: 10, scale: 2
    t.decimal "total_line_items_price", precision: 10, scale: 2
    t.decimal "total_tax", precision: 10, scale: 2
    t.integer "total_weight"
    t.decimal "total_price", precision: 10, scale: 2
    t.datetime "updated_at"
    t.jsonb "discount_codes"
    t.datetime "synced_at"
    t.jsonb "raw_line_items", default: [], null: false
    t.jsonb "raw_shipping_lines", default: [], null: false
    t.string "browser_ip"
    t.index ["address_id"], name: "index_charges_on_address_id"
    t.index ["charge_id"], name: "index_charges_on_charge_id"
    t.index ["customer_id"], name: "index_charges_on_customer_id"
  end

  create_table "charges_shipping_address", force: :cascade do |t|
    t.string "charge_id"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "company"
    t.string "country"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "province"
    t.string "zip"
    t.index ["charge_id"], name: "index_charges_shipping_address_on_charge_id"
  end

  create_table "charges_shipping_lines", force: :cascade do |t|
    t.string "charge_id"
    t.string "code"
    t.decimal "price", precision: 10, scale: 2
    t.string "source"
    t.string "title"
    t.jsonb "tax_lines"
    t.string "carrier_identifier"
    t.string "request_fulfillment_service_id"
    t.index ["charge_id"], name: "index_charges_shipping_lines_on_charge_id"
  end

  create_table "config", primary_key: "key", id: :string, limit: 100, force: :cascade do |t|
    t.jsonb "val"
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
  end

  create_table "current_products", force: :cascade do |t|
    t.string "prod_id_key"
    t.string "prod_id_value"
    t.string "next_month_prod_id"
    t.index ["prod_id_key"], name: "index_current_products_on_prod_id_key"
    t.index ["prod_id_value"], name: "index_current_products_on_prod_id_value"
  end

  create_table "customer_info", force: :cascade do |t|
    t.string "shopify_id"
    t.string "subscription_id"
    t.index ["shopify_id"], name: "index_customer_info_on_shopify_id"
    t.index ["subscription_id"], name: "index_customer_info_on_subscription_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "customer_id"
    t.string "customer_hash"
    t.string "shopify_customer_id"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_name"
    t.string "last_name"
    t.string "billing_address1"
    t.string "billing_address2"
    t.string "billing_zip"
    t.string "billing_city"
    t.string "billing_company"
    t.string "billing_province"
    t.string "billing_country"
    t.string "billing_phone"
    t.string "processor_type"
    t.string "status"
    t.datetime "synced_at"
    t.index ["customer_id"], name: "index_customers_on_customer_id"
    t.index ["shopify_customer_id"], name: "index_customers_on_shopify_customer_id"
  end

  create_table "ellie_collects", force: :cascade do |t|
    t.bigint "collect_id"
    t.bigint "collection_id"
    t.bigint "product_id"
    t.boolean "featured", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "position"
    t.string "sort_value"
  end

  create_table "ellie_custom_collections", force: :cascade do |t|
    t.bigint "collection_id"
    t.string "handle"
    t.string "title"
    t.datetime "updated_at"
    t.text "body_html"
    t.datetime "published_at"
    t.string "sort_order"
    t.string "template_suffix"
    t.string "published_scope"
  end

  create_table "ellie_variants", force: :cascade do |t|
    t.bigint "variant_id"
    t.string "title"
    t.decimal "price", precision: 10, scale: 2
    t.bigint "sku"
    t.integer "position"
    t.string "inventory_policy"
    t.decimal "compare_at_price", precision: 10, scale: 2
    t.bigint "product_id"
    t.string "fulfillment_service"
    t.string "inventory_management"
    t.string "option1"
    t.string "option2"
    t.string "option3"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "taxable"
    t.string "barcode"
    t.decimal "weight", precision: 10, scale: 2
    t.string "weight_unit"
    t.integer "inventory_quantity"
    t.bigint "image_id"
    t.integer "grams"
    t.bigint "inventory_item_id"
    t.string "tax_code"
    t.integer "old_inventory_quantity"
    t.boolean "requires_shipping"
  end

  create_table "matching_products", force: :cascade do |t|
    t.string "new_product_title"
    t.string "incoming_product_id"
    t.boolean "threepk", default: false
    t.string "outgoing_product_id"
    t.index ["incoming_product_id"], name: "index_matching_products_on_incoming_product_id"
  end

  create_table "order_billing_address", force: :cascade do |t|
    t.string "order_id"
    t.string "province"
    t.string "city"
    t.string "first_name"
    t.string "last_name"
    t.string "zip"
    t.string "country"
    t.string "address1"
    t.string "address2"
    t.string "company"
    t.string "phone"
    t.index ["order_id"], name: "index_order_billing_address_on_order_id"
  end

  create_table "order_line_items_fixed", force: :cascade do |t|
    t.string "order_id"
    t.string "shopify_variant_id"
    t.string "title"
    t.string "variant_title"
    t.string "subscription_id"
    t.integer "quantity"
    t.string "shopify_product_id"
    t.string "product_title"
    t.index ["order_id"], name: "index_order_line_items_fixed_on_order_id"
    t.index ["subscription_id"], name: "index_order_line_items_fixed_on_subscription_id"
  end

  create_table "order_line_items_variable", force: :cascade do |t|
    t.string "order_id"
    t.string "name"
    t.string "value"
    t.index ["order_id"], name: "index_order_line_items_variable_on_order_id"
  end

  create_table "order_shipping_address", force: :cascade do |t|
    t.string "order_id"
    t.string "province"
    t.string "city"
    t.string "first_name"
    t.string "last_name"
    t.string "zip"
    t.string "country"
    t.string "address1"
    t.string "address2"
    t.string "company"
    t.string "phone"
    t.index ["order_id"], name: "index_order_shipping_address_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_id"
    t.string "transaction_id"
    t.string "charge_status"
    t.string "payment_processor"
    t.integer "address_is_active"
    t.string "status"
    t.string "order_type"
    t.string "charge_id"
    t.string "address_id"
    t.string "shopify_id"
    t.string "shopify_order_id"
    t.string "shopify_order_number"
    t.string "shopify_cart_token"
    t.datetime "shipping_date"
    t.datetime "scheduled_at"
    t.datetime "shipped_date"
    t.datetime "processed_at"
    t.string "customer_id"
    t.string "first_name"
    t.string "last_name"
    t.integer "is_prepaid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email"
    t.jsonb "line_items"
    t.decimal "total_price", precision: 10, scale: 2
    t.jsonb "shipping_address"
    t.jsonb "billing_address"
    t.datetime "synced_at"
    t.index ["address_id"], name: "index_orders_on_address_id"
    t.index ["charge_id"], name: "index_orders_on_charge_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["order_id"], name: "index_orders_on_order_id"
    t.index ["shopify_id"], name: "index_orders_on_shopify_id"
    t.index ["shopify_order_id"], name: "index_orders_on_shopify_order_id"
    t.index ["shopify_order_number"], name: "index_orders_on_shopify_order_number"
    t.index ["transaction_id"], name: "index_orders_on_transaction_id"
  end

  create_table "product_tags", force: :cascade do |t|
    t.string "product_id", null: false
    t.string "tag", null: false
    t.datetime "active_start"
    t.datetime "active_end"
    t.string "theme_id"
  end

  create_table "products", force: :cascade do |t|
    t.text "body_html", default: "", null: false
    t.string "shopify_id", null: false
    t.string "handle"
    t.jsonb "images"
    t.jsonb "options"
    t.string "product_type"
    t.datetime "published_at"
    t.json "image"
    t.string "published_scope"
    t.string "tags"
    t.string "template_suffix"
    t.string "title"
    t.string "metafields_global_title_tag"
    t.string "metafields_global_description_tag"
    t.jsonb "variants"
    t.string "vendor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopify_customers", force: :cascade do |t|
    t.boolean "accepts_marketing"
    t.jsonb "addresses"
    t.datetime "created_at"
    t.jsonb "default_address"
    t.string "email"
    t.string "first_name"
    t.string "customer_id"
    t.string "last_name"
    t.string "last_order_id"
    t.string "last_order_name"
    t.jsonb "metafield"
    t.string "multipass_identifier"
    t.string "note"
    t.integer "orders_count"
    t.string "phone"
    t.string "state"
    t.string "tags"
    t.boolean "tax_exempt"
    t.string "total_spent"
    t.datetime "updated_at"
    t.boolean "verified_email"
  end

  create_table "shopify_orders", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "app_id"
    t.json "billing_address"
    t.string "browser_ip"
    t.boolean "buyer_accepts_marketing"
    t.datetime "cancelled_at"
    t.string "cancel_reason"
    t.string "cart_token"
    t.bigint "checkout_id"
    t.string "checkout_token"
    t.datetime "closed_at"
    t.boolean "confirmed"
    t.string "contact_email"
    t.datetime "created_at"
    t.float "currency"
    t.json "customer"
    t.string "customer_locale"
    t.bigint "device_id"
    t.json "discount_codes"
    t.string "email"
    t.string "financial_status"
    t.json "fulfillments"
    t.string "fulfillment_status"
    t.string "gateway"
    t.string "landing_site"
    t.string "landing_site_ref"
    t.json "line_items"
    t.bigint "location_id"
    t.string "name"
    t.text "note"
    t.json "note_attributes"
    t.integer "number"
    t.integer "order_number"
    t.string "order_status_url"
    t.json "payment_gateway_names"
    t.string "phone"
    t.datetime "processed_at"
    t.string "processing_method"
    t.string "reference"
    t.string "referring_site"
    t.json "refunds"
    t.json "shipping_address"
    t.json "shipping_lines"
    t.string "source_identifier"
    t.string "source_name"
    t.string "source_url"
    t.float "subtotal_price"
    t.string "tags"
    t.boolean "taxes_included"
    t.json "tax_lines"
    t.boolean "test"
    t.string "token"
    t.float "total_discounts"
    t.float "total_line_items_price"
    t.float "total_price"
    t.float "total_price_usd"
    t.float "total_tax"
    t.integer "total_weight"
    t.datetime "updated_at"
    t.bigint "user_id"
    t.datetime "sent_to_acs_at"
  end

  create_table "skip_reasons", force: :cascade do |t|
    t.string "customer_id", null: false
    t.string "shopify_customer_id", null: false
    t.string "subscription_id", null: false
    t.string "charge_id"
    t.string "reason"
    t.datetime "skipped_to"
    t.boolean "skip_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["charge_id"], name: "index_skip_reasons_on_charge_id"
    t.index ["customer_id"], name: "index_skip_reasons_on_customer_id"
    t.index ["shopify_customer_id"], name: "index_skip_reasons_on_shopify_customer_id"
    t.index ["subscription_id"], name: "index_skip_reasons_on_subscription_id"
  end

  create_table "sub_line_items", force: :cascade do |t|
    t.string "subscription_id"
    t.string "name"
    t.string "value"
    t.index ["subscription_id"], name: "index_sub_line_items_on_subscription_id"
  end

  create_table "subscription_update", force: :cascade do |t|
    t.string "subscription_id"
    t.string "customer_id"
    t.string "first_name"
    t.string "last_name"
    t.string "product_title"
    t.string "shopify_product_id"
    t.string "shopify_variant_id"
    t.string "sku"
    t.boolean "updated", default: false
    t.datetime "updated_at"
    t.index ["customer_id"], name: "index_subscription_update_on_customer_id"
    t.index ["subscription_id"], name: "index_subscription_update_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "subscription_id"
    t.string "address_id"
    t.string "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "next_charge_scheduled_at"
    t.datetime "cancelled_at"
    t.string "product_title"
    t.decimal "price", precision: 10, scale: 2
    t.integer "quantity"
    t.string "status"
    t.string "shopify_product_id"
    t.string "shopify_variant_id"
    t.string "sku"
    t.string "order_interval_unit"
    t.integer "order_interval_frequency"
    t.integer "charge_interval_frequency"
    t.integer "order_day_of_month"
    t.integer "order_day_of_week"
    t.jsonb "raw_line_item_properties"
    t.datetime "synced_at"
    t.integer "expire_after_specific_number_charges"
    t.index ["address_id"], name: "index_subscriptions_on_address_id"
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["expire_after_specific_number_charges"], name: "index_subscriptions_on_expire_after_specific_number_charges"
    t.index ["subscription_id"], name: "index_subscriptions_on_subscription_id"
    t.index ["subscription_id"], name: "sub_id", unique: true
  end

  create_table "subscriptions_updated", force: :cascade do |t|
    t.string "subscription_id"
    t.string "customer_id"
    t.datetime "updated_at"
    t.datetime "next_charge_scheduled_at"
    t.string "product_title"
    t.string "status"
    t.string "sku"
    t.string "shopify_product_id"
    t.string "shopify_variant_id"
    t.boolean "updated", default: false
    t.datetime "processed_at"
    t.jsonb "raw_line_items"
    t.index ["customer_id"], name: "index_subscriptions_updated_on_customer_id"
    t.index ["subscription_id"], name: "index_subscriptions_updated_on_subscription_id"
  end

  create_table "switchable_products", force: :cascade do |t|
    t.string "product_title"
    t.string "product_id"
    t.boolean "threepk", default: false
    t.index ["product_id"], name: "index_skippable_products_on_product_id"
  end

  create_table "update_line_items", force: :cascade do |t|
    t.string "subscription_id"
    t.jsonb "properties"
    t.boolean "updated", default: false
  end

  create_table "update_products", force: :cascade do |t|
    t.string "sku"
    t.string "product_title"
    t.string "shopify_product_id"
    t.string "shopify_variant_id"
    t.index ["product_title"], name: "index_update_products_on_product_title"
    t.index ["shopify_product_id"], name: "index_update_products_on_shopify_product_id"
    t.index ["shopify_variant_id"], name: "index_update_products_on_shopify_variant_id"
    t.index ["sku"], name: "index_update_products_on_sku"
  end

end
