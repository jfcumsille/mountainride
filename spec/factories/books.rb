# == Schema Information
#
# Table name: books
#
#  id                 :integer          not null, primary key
#  title              :string           not null
#  order              :integer          not null
#  book_collection_id :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_books_on_book_collection_id            (book_collection_id)
#  index_books_on_book_collection_id_and_order  (book_collection_id,order) UNIQUE
#

FactoryBot.define do
  factory :book do
    title { "Harry Potter and the Philosopher's Stone" }
    order { 1 }
    book_collection { association(:book_collection) }
  end
end
