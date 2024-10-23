ActiveAdmin.register BookCollection do
  permit_params :name

  index do
    selectable_column
    id_column
    column :name
    column :books do  |book_collection|
      link_to book_collection.books.count,
              admin_books_path({ q: { book_collection_id_eq: book_collection.id } })
    end
    column :created_at
    column :updated_at
    actions
  end

  filter :name

  form do |f|
    f.inputs do
      f.input :name
    end
    f.actions
  end
end
