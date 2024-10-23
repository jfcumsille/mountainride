ActiveAdmin.register Author do
  permit_params :real_name, :public_name

  index do
    selectable_column
    id_column
    column :real_name
    column :public_name
    column :created_at
    column :updated_at
    actions
  end

  filter :real_name
  filter :public_name

  form do |f|
    f.inputs do
      f.input :real_name
      f.input :public_name
    end
    f.actions
  end
end
