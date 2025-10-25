class CreateSkiCenters < ActiveRecord::Migration[8.2]
  def change
    create_table :ski_centers do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :address
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :website_url
      t.integer :position
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :ski_centers, :slug, unique: true
    add_index :ski_centers, :active
    add_index :ski_centers, :position
  end
end
