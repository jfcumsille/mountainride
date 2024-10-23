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

class BookCollection < ApplicationRecord
  validates :name, presence: true
  validates :name, uniqueness: true

  before_save :titleize_attribute

  has_many :books, -> { order(order: :asc) }, dependent: :destroy, inverse_of: :book_collection

  private

  def titleize_attribute
    self.name = name.titleize
  end
end
