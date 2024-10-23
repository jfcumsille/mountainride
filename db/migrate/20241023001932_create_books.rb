class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title
      t.integer :order
      t.references :book_collection, null: false, foreign_key: true

      t.timestamps
    end
  end
end
