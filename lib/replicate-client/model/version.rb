# frozen_string_literal: true

module ReplicateClient
  class Model
    class Version
      INDEX_PATH = "/versions"

      class << self
        # Find a version of a model.
        #
        # @param owner [String] The owner of the model.
        # @param name [String] The name of the model.
        # @param version_id [String] The version id of the model.
        #
        # @return [ReplicateClient::Model::Version]
        def find_by!(owner:, name:, version_id:)
          path = build_path(owner: owner, name: name, version_id: version_id)
          response = ReplicateClient.client.get(path)
          new(response)
        end

        # Find a version of a model.
        #
        # @param owner [String] The owner of the model.
        # @param name [String] The name of the model.
        # @param version_id [String] The version id of the model.
        #
        # @return [ReplicateClient::Model::Version]
        def find_by(owner:, name:, version_id:)
          find_by!(owner: owner, name: name, version_id: version_id)
        rescue ReplicateClient::NotFoundError
          nil
        end

        # Get all versions of a model.
        #
        # @param owner [String] The owner of the model.
        # @param name [String] The name of the model.
        #
        # @return [Array<ReplicateClient::Model::Version>]
        def where(owner:, name:)
          versions = []

          auto_paging_each(owner: owner, name: name) do |version|
            versions << version
          end

          versions
        end

        # Paginate through all models.
        #
        # @param name [String] The name of the model.
        # @param owner [String] The owner of the model.
        # @yield [ReplicateClient::Model] Yields a model.
        #
        # @return [void]
        def auto_paging_each(owner:, name:, &block)
          cursor = nil
          model_path = Model.build_path(owner: owner, name: name)

          loop do
            url_params = cursor ? "?cursor=#{cursor}" : ""
            attributes = ReplicateClient.client.get("#{model_path}#{INDEX_PATH}#{url_params}")

            versions = attributes["results"].map { |version| new(version) }

            versions.each(&block)

            cursor = attributes["next"] ? URI.decode_www_form(URI.parse(attributes["next"]).query).to_h["cursor"] : nil
            break if cursor.nil?
          end
        end

        # Build the path for the model version.
        #
        # @param owner [String] The owner of the model.
        # @param name [String] The name of the model.
        # @param version_id [String] The version id of the model.
        #
        # @return [String]
        def build_path(owner:, name:, version_id:)
          model_path = Model.build_path(owner: owner, name: name)
          "#{model_path}#{INDEX_PATH}/#{version_id}"
        end
      end

      # The ID of the model version.
      #
      # @return [String]
      attr_accessor :id

      # The date the model version was created.
      #
      # @return [Time]
      attr_accessor :created_at

      # The cog version of the model version.
      #
      # @return [String]
      attr_accessor :cog_version

      # The OpenAPI schema of the model version.
      #
      # @return [Hash]
      attr_accessor :openapi_schema

      def initialize(attributes)
        @id = attributes["id"]
        @created_at = Time.parse(attributes["created_at"])
        @cog_version = attributes["cog_version"]
        @openapi_schema = attributes["openapi_schema"]
      end

      # Create a new prediction.
      #
      # @param input [Hash] The input data for the prediction.
      # @param webhook_url [String, nil] A URL to receive webhook notifications.
      # @param webhook_events_filter [Array, nil] The events to trigger webhook requests.
      #
      # @return [ReplicateClient::Prediction]
      def create_prediction!(input:, webhook_url: nil, webhook_events_filter: nil)
        Prediction.create!(
          version: self,
          input: input,
          webhook_url: webhook_url,
          webhook_events_filter: webhook_events_filter
        )
      end
    end
  end
end
