class AddNonNullToAuthorModel < ActiveRecord::Migration[8.1]
  def change
    change_column_null :authors, :real_name, false
    change_column_null :authors, :public_name, false
  end
end
