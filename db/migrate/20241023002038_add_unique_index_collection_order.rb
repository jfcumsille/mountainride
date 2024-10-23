class AddUniqueIndexCollectionOrder < ActiveRecord::Migration[8.1]
  def change
    add_index :books, [:book_collection_id, :order], unique: true
  end
end
