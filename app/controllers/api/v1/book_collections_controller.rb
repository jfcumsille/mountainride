class Api::V1::BookCollectionsController < Api::V1::BaseController
  def index
    respond_with book_collections
  end

  private

  def book_collections
    @book_collections ||= BookCollection.all
  end
end
