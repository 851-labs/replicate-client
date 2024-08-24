# frozen_string_literal: true

require "faraday"
require "time"

require_relative "replicate-client/client"
require_relative "replicate-client/prediction"
require_relative "replicate-client/version"
require_relative "replicate-client/model"
require_relative "replicate-client/hardware"
require_relative "replicate-client/training"
require_relative "replicate-client/deployment"
require_relative "replicate-client/webhook"

module ReplicateClient
  class Error < StandardError; end
  class UnauthorizedError < Error; end
  class NotFoundError < Error; end
  class ServerError < Error; end
  class ConfigurationError < Error; end
  class ForbiddenError < Error; end

  class Configuration
    DEFAULT_URI_BASE = "https://api.replicate.com/v1"
    DEFAULT_REQUEST_TIMEOUT = 120

    # The access token for the API.
    #
    # @return [String]
    attr_accessor :access_token

    # The base URI for the API.
    #
    # @return [String]
    attr_accessor :uri_base

    # The request timeout in seconds.
    #
    # @return [Integer]
    attr_accessor :request_timeout

    # The URL to send webhook events to.
    #
    # @return [String]
    attr_accessor :webhook_url

    # Initialize the configuration.
    #
    # @return [ReplicateClient::Configuration]
    def initialize
      @access_token = nil
      @webhook_url = nil
      @uri_base = DEFAULT_URI_BASE
      @request_timeout = DEFAULT_REQUEST_TIMEOUT
    end
  end

  class << self
    # The configuration for the client.
    #
    # @return [ReplicateClient::Configuration]
    attr_accessor :configuration

    # Configure the client.
    #
    # @yield [ReplicateClient::Configuration] The configuration for the client.
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    # The client for the API.
    #
    # @return [ReplicateClient::Client]
    def client
      @client ||= Client.new(configuration)
    end
  end
end
