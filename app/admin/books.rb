ActiveAdmin.register Book do
  permit_params :title, :order, :book_collection_id

  index do
    selectable_column
    id_column
    column :title
    column :order
    column :book_collection do |book|
      link_to book.book_collection.name, admin_book_collection_path(book.book_collection)
    end
    column :created_at
    column :updated_at
    actions
  end

  filter :title

  form do |f|
    f.inputs do
      f.input :title
      f.input :order
      f.input :book_collection_id, as: :select, collection: BookCollection.pluck(:name, :id)
    end
    f.actions
  end
end
