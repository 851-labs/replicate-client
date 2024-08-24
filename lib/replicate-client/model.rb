# frozen_string_literal: true

require_relative "model/version"

module ReplicateClient
  class Model
    INDEX_PATH = "/models"

    module Visibility
      PUBLIC = "public"
      PRIVATE = "private"
    end

    class << self
      # Find a model.
      #
      # @param owner [String] The owner of the model.
      # @param name [String] The name of the model.
      #
      # @return [ReplicateClient::Model]
      def find_by!(owner:, name:, version_id: nil)
        path = build_path(owner: owner, name: name)
        response = ReplicateClient.client.get(path)
        new(response, version_id: version_id)
      end

      # Find a model.
      #
      # @param owner [String] The owner of the model.
      # @param name [String] The name of the model.
      # @param version_id [String] The version id of the model to use.
      #
      # @return [ReplicateClient::Model]
      def find_by(owner:, name:, version_id: nil)
        find_by!(owner: owner, name: name, version_id: version_id)
      rescue ReplicateClient::NotFoundError
        nil
      end

      # Find a model by name.
      # The name should be in the format "owner/name".
      #
      # @param name [String] The name of the model.
      # @param version_id [String] The version id of the model to use.
      #
      # @return [ReplicateClient::Model]
      def find(name, version_id: nil)
        find_by!(**parse_model_name(name), version_id: version_id)
      end

      # Build the path for the model.
      #
      # @param owner [String] The owner of the model.
      # @param name [String] The name of the model.
      #
      # @return [String]
      def build_path(owner:, name:)
        "#{INDEX_PATH}/#{owner}/#{name}"
      end

      # Paginate through all models.
      #
      # @yield [ReplicateClient::Model] Yields a model.
      #
      # @return [void]
      def auto_paging_each(&block)
        cursor = nil

        loop do
          url_params = cursor ? "?cursor=#{cursor}" : ""
          attributes = ReplicateClient.client.get("#{INDEX_PATH}#{url_params}")

          models = attributes["results"].map { |model| new(model) }

          models.each(&block)

          cursor = attributes["next"] ? URI.decode_www_form(URI.parse(attributes["next"]).query).to_h["cursor"] : nil
          break if cursor.nil?
        end
      end

      # Create a new model.
      #
      # @param owner [String] The owner of the model.
      # @param name [String] The name of the model.
      # @param description [String] A description of the model.
      # @param visibility [String] "public" or "private".
      # @param hardware [String] The SKU for the hardware used to run the model.
      # @param github_url [String, nil] A URL for the model’s source code on GitHub.
      # @param paper_url [String, nil] A URL for the model’s paper.
      # @param license_url [String, nil] A URL for the model’s license.
      # @param cover_image_url [String, nil] A URL for the model’s cover image.
      #
      # @return [ReplicateClient::Model]
      def create!(
        owner:,
        name:,
        description:,
        visibility:,
        hardware:,
        github_url: nil,
        paper_url: nil,
        license_url: nil,
        cover_image_url: nil
      )
        new_attributes = {
          owner: owner,
          name: name,
          description: description,
          visibility: visibility,
          hardware: hardware,
          github_url: github_url,
          paper_url: paper_url,
          license_url: license_url,
          cover_image_url: cover_image_url
        }

        attributes = ReplicateClient.client.post("/models", new_attributes)

        new(attributes)
      end

      # Parse the model name.
      #
      # @param model_name [String] The name of the model.
      #
      # @return [Hash]
      def parse_model_name(model_name)
        parts = model_name.split("/")

        {
          owner: parts[0],
          name: parts[1]
        }
      end
    end

    # The URL of the model.
    #
    # @return [String]
    attr_accessor :url

    # The name of the user or organization that will own the model.
    #
    # @return [String]
    attr_accessor :owner

    # The name of the model.
    #
    # @return [String]
    attr_accessor :name

    # A description of the model.
    #
    # @return [String]
    attr_accessor :description

    # Whether the model should be public or private. A public model can be viewed and run by anyone, whereas
    # a private model can be viewed and run only by the user or organization members that own the model.
    #
    # @return [String] "public" or "private"
    attr_accessor :visibility

    # A URL for the model’s source code on GitHub.
    #
    # @return [String]
    attr_accessor :github_url

    # A URL for the model’s paper.
    #
    # @return [String]
    attr_accessor :paper_url

    # A URL for the model’s license.
    #
    # @return [String]
    attr_accessor :license_url

    # The number of times the model has been run.
    #
    # @return [Integer]
    attr_accessor :run_count

    # A URL for the model’s cover image. This should be an image file.
    #
    # @return [String]
    attr_accessor :cover_image_url

    # The default example of the model.
    #
    # @return [Hash]
    attr_accessor :default_example

    # The current version id of the model.
    #
    # @return [String]
    attr_accessor :version_id

    # The id of the latest version of the model.
    #
    # @return [Hash]
    attr_accessor :latest_version_id

    # Initialize a new model.
    #
    # @param attributes [Hash] The attributes of the model.
    # @param version_id [String] The version of the model to use.
    #
    # @return [ReplicateClient::Model]
    def initialize(attributes, version_id: nil)
      reset_attributes(attributes, version_id: version_id)
    end

    # The path of the model.
    #
    # @return [String]
    def path
      self.class.build_path(owner: owner, name: name)
    end

    # Delete the model.
    #
    # @return [void]
    def destroy!
      ReplicateClient.client.delete(path)
    end

    # The path of the current version.
    #
    # @return [String]
    def version_path
      Version.build_path(owner: owner, name: name, version_id: version_id)
    end

    # The version of the model.
    #
    # @return [ReplicateClient::Model::Version]
    def version
      @version ||= Version.find_by!(owner: owner, name: name, version_id: version_id)
    end

    # The latest version of the model.
    #
    # @return [ReplicateClient::Model::Version]
    def latest_version
      @latest_version ||= Version.find_by!(owner: owner, name: name, version_id: latest_version_id)
    end

    # The versions of the model.
    #
    # @return [Array<ReplicateClient::Model::Version>]
    def versions
      @versions ||= Version.where(owner: owner, name: name)
    end

    # Create a new prediction for the model.
    #
    # @param input [Hash] The input data for the prediction.
    #
    # @return [ReplicateClient::Prediction]
    def create_prediction!(input:, webhook_url: nil, webhook_events_filter: nil)
      if version_id.nil?
        Prediction.create_for_official_model!(
          model: self,
          input: input,
          webhook_url: webhook_url,
          webhook_events_filter: webhook_events_filter
        )
      else
        Prediction.create!(
          version: version_id,
          input: input,
          webhook_url: webhook_url,
          webhook_events_filter: webhook_events_filter
        )
      end
    end

    # Reload the model.
    #
    # @return [void]
    def reload!
      attributes = ReplicateClient.client.get(path)
      reset_attributes(attributes, version_id: version_id)
    end

    # Check if the model is public.
    #
    # @return [Boolean]
    def public?
      visibility == Visibility::PUBLIC
    end

    # Check if the model is private.
    #
    # @return [Boolean]
    def private?
      visibility == Visibility::PRIVATE
    end

    # Returns the full name of the model in "owner/name" format.
    #
    # @return [String]
    def full_name
      "#{owner}/#{name}"
    end

    private

    # Set the attributes of the model.
    #
    # @param attributes [Hash] The attributes of the model.
    # @param version_id [String] The version of the model to use.
    #
    # @return [void]
    def reset_attributes(attributes, version_id: nil)
      @owner = attributes["owner"]
      @name = attributes["name"]
      @description = attributes["description"]
      @visibility = attributes["visibility"]
      @github_url = attributes["github_url"]
      @paper_url = attributes["paper_url"]
      @license_url = attributes["license_url"]
      @run_count = attributes["run_count"]
      @cover_image_url = attributes["cover_image_url"]
      @default_example = attributes["default_example"]
      @latest_version_id = attributes.dig("latest_version", "id")
      @version_id = version_id || attributes.dig("latest_version", "id")

      @version = nil
      @versions = nil
      @latest_version = nil
    end
  end
end
