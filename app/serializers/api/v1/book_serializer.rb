class Api::V1::BookSerializer < ActiveModel::Serializer
  attributes :id, :title, :order, :book_collection_id
end
