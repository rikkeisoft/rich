class AddFrequentlyUsedToRichFile < ActiveRecord::Migration
  def change
    add_column :rich_rich_files, :frequently_used, :boolean, default: false
  end
end
