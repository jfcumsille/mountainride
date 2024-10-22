class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :authors do |t|
      t.string :real_name
      t.string :public_name

      t.timestamps
    end
  end
end
