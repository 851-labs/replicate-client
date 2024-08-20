# frozen_string_literal: true

module ReplicateClient
  class Client
    # Initialize the client.
    #
    # @param configuration [ReplicateClient::Configuration] The configuration for the client.
    #
    # @return [ReplicateClient::Client]
    def initialize(configuration = ReplicateClient.configuration)
      @configuration = configuration
    end

    # Make a POST request to the API.
    #
    # @param path [String] The path to the API endpoint.
    # @param payload [Hash] The payload to send to the API.
    #
    # @return [Hash] The response from the API.
    def post(path, payload)
      response = connection.post(build_url(path)) do |request|
        request.headers["Authorization"] = "Bearer #{@configuration.access_token}"
        request.headers["Content-Type"] = "application/json"
        request.headers["Accept"] = "application/json"
        request.body = payload.compact.to_json
      end

      handle_error(response) unless response.success?

      JSON.parse(response.body)
    end

    # Make a GET request to the API.
    #
    # @param path [String] The path to the API endpoint.
    #
    # @return [Hash] The response from the API.
    def get(path)
      puts "GET #{path}"

      response = connection.get(build_url(path)) do |request|
        request.headers["Authorization"] = "Bearer #{@configuration.access_token}"
        request.headers["Content-Type"] = "application/json"
      end

      handle_error(response) unless response.success?

      JSON.parse(response.body)
    end

    # Make a DELETE request to the API.
    #
    # @param path [String] The path to the API endpoint.
    #
    # @return [void]
    def delete(path)
      response = connection.delete(build_url(path)) do |request|
        request.headers["Authorization"] = "Bearer #{@configuration.access_token}"
        request.headers["Content-Type"] = "application/json"
      end

      handle_error(response) unless response.success?
    end

    def patch(path, payload)
      response = connection.patch(build_url(path)) do |request|
        request.headers["Authorization"] = "Bearer #{@configuration.access_token}"
        request.headers["Content-Type"] = "application/json"
        request.headers["Accept"] = "application/json"
        request.body = payload.compact.to_json
      end

      handle_error(response) unless response.success?

      JSON.parse(response.body)
    end

    # Handle errors from the API.
    #
    # @param response [Faraday::Response] The response from the API.
    #
    # @return [void]
    def handle_error(response)
      case response.status
      when 401
        raise UnauthorizedError, response.body
      when 403
        raise ForbiddenError, response.body
      when 404
        raise NotFoundError, response.body
      else
        raise ServerError, response.body
      end
    end

    private

    # Build the URL for the API.
    #
    # @param path [String] The path to the API endpoint.
    def build_url(path)
      "#{@configuration.uri_base}#{path}"
    end

    # Create a connection to the API.
    #
    # @return [Faraday::Connection]
    def connection
      Faraday.new do |faraday|
        faraday.request :url_encoded
        faraday.options.timeout = @configuration.request_timeout
        faraday.options.open_timeout = @configuration.request_timeout
      end
    end
  end
end
