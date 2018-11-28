class CreateShopifyCustomerTagFix < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_customer_tag_fixes do |t|
      t.string :customer_id
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :tags
      t.boolean :is_processed, default: false
    end
  end
end
