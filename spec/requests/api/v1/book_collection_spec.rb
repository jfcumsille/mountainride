require 'rails_helper'

RSpec.describe 'BookCollections' do
  describe 'GET #index' do
    let(:book_collection) { create(:book_collection) }
    let!(:first_book) { create(:book, book_collection:) }
    let!(:second_book) { create(:book, book_collection:) }
    let(:other_book) { create(:book) }
    let(:json_response) { response.parsed_body }
    let(:books_response) do
      [
        {
          id: first_book.id,
          title: first_book.title,
          order: first_book.order,
          book_collection_id: book_collection.id
        },
        {
          id: second_book.id,
          title: second_book.title,
          order: second_book.order,
          book_collection_id: book_collection.id
        }
      ]
    end
    let(:expected_response) do
      [
        {
          id: book_collection.id,
          name: book_collection.name,
          books: books_response
        }
      ].to_json
    end

    it 'returns a successful response' do
      get '/api/v1/book_collections', params: {}, headers: { 'Accept' => 'application/json' }
      expect(response).to be_successful
      expect(json_response).to eq(JSON.parse(expected_response))
    end
  end
end
