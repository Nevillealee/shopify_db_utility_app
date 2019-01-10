class ChangeTagFixTableName < ActiveRecord::Migration[5.2]
  def change
    rename_table :shopify_customer_tag_fixes, :prospect_tag_fixes
  end
end
