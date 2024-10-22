class CreateBookCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :book_collections do |t|
      t.string :name

      t.timestamps
    end
  end
end
