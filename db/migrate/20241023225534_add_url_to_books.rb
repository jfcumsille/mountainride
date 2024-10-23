class AddUrlToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :url, :string
  end
end
