class AddUniqueIndexToBookCollectionName < ActiveRecord::Migration[8.1]
  def change
    add_index :book_collections, :name, unique: true
    change_column_null :book_collections, :name, false
  end
end
