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

require 'rails_helper'

RSpec.describe Book do
  subject { build(:book) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:order) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:book_collection) }
  end

  describe 'factory' do
    it { is_expected.to be_valid }
  end
end
