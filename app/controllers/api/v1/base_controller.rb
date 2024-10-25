class Api::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token

  self.responder = ApiResponder
  respond_to :json

  before_action do
    self.namespace_for_serializer = ::Api::V1
  end
end
