# frozen_string_literal: true

module ReplicateClient
  class Hardware
    INDEX_PATH = "/hardware"

    class << self
      # List all available hardware.
      #
      # @param client [ReplicateClient::Client] The client to use for requests.
      #
      # @return [Array<ReplicateClient::Hardware>]
      def all(client: ReplicateClient.client)
        response = client.get(INDEX_PATH)
        response.map { |attributes| new(attributes) }
      end

      # Find hardware by SKU.
      #
      # @param sku [String] The SKU of the hardware.
      # @param client [ReplicateClient::Client] The client to use for requests.
      #
      # @return [ReplicateClient::Hardware, nil]
      def find_by(sku:, client: ReplicateClient.client)
        all(client: client).find { |hardware| hardware.sku == sku }
      end
    end

    # The SKU of the hardware.
    #
    # @return [String]
    attr_accessor :sku

    # The name of the hardware.
    #
    # @return [String]
    attr_accessor :name

    # Initialize a new hardware instance.
    #
    # @param attributes [Hash] The attributes of the hardware.
    #
    # @return [ReplicateClient::Hardware]
    def initialize(attributes)
      @sku = attributes["sku"]
      @name = attributes["name"]
    end

    # Convert the hardware object to a string representation.
    #
    # @return [String]
    def to_s
      "#{name} (#{sku})"
    end
  end
end
