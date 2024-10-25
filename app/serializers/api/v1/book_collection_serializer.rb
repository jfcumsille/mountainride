class Api::V1::BookCollectionSerializer < ActiveModel::Serializer
  attributes :id, :name
  has_many :books
end
