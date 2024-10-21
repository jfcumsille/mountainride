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

require 'rails_helper'

RSpec.describe BookCollection, type: :model do
  subject { build(:book_collection) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe 'factory' do
    it { is_expected.to be_valid }
  end

  describe 'callbacks' do
    it 'titleizes the name' do
      book_collection = create(:book_collection, name: 'harry potter')
      expect(book_collection.name).to eq('Harry Potter')
    end
  end
end
