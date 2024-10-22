# == Schema Information
#
# Table name: book_collections
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_book_collections_on_name  (name) UNIQUE
#

FactoryBot.define do
  factory :book_collection do
    name { 'Harry Potter' }
  end
end
