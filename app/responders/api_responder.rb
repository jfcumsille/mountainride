class ApiResponder < ActionController::Responder
  def respond
    return head :no_content if delete?

    display resource, status: status_code, namespace: controller.namespace_for_serializer
  end

  private

  def display(_resource, given_options = {})
    controller.render options.merge(given_options).merge(
      json: serializer(given_options).as_json
    )
  end

  def serializer(given_options = {})
    return resource if resource.respond_to?(:serializer_class)

    serializer_class = ActiveModel::Serializer.serializer_for(resource, given_options)

    if serializer_class.present?
      serializer_class.new(resource, given_options)
    else
      resource
    end
  end

  def status_code
    return :created if post?

    :ok
  end
end
