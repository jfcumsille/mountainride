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
#  url                :string
#
# Indexes
#
#  index_books_on_book_collection_id            (book_collection_id)
#  index_books_on_book_collection_id_and_order  (book_collection_id,order) UNIQUE
#

class Book < ApplicationRecord
  belongs_to :book_collection

  validates :title, presence: true
  validates :order, presence: true
end
