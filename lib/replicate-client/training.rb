# frozen_string_literal: true

module ReplicateClient
  class Training
    INDEX_PATH = "/trainings"

    module Status
      STARTING   = "starting"
      PROCESSING = "processing"
      SUCCEEDED  = "succeeded"
      FAILED     = "failed"
      CANCELED   = "canceled"
    end

    class << self
      # List all trainings.
      #
      # @yield [ReplicateClient::Training] Yields a training.
      #
      # @return [void]
      def auto_paging_each(&block)
        cursor = nil

        loop do
          url_params = cursor ? "?cursor=#{cursor}" : ""
          attributes = ReplicateClient.client.get("#{INDEX_PATH}#{url_params}")

          trainings = attributes["results"].map { |training| new(training) }

          trainings.each(&block)

          cursor = attributes["next"] ? URI.decode_www_form(URI.parse(attributes["next"]).query).to_h["cursor"] : nil
          break if cursor.nil?
        end
      end

      # Create a new training.
      #
      # @param owner [String] The owner of the model.
      # @param name [String] The name of the model.
      # @param version [ReplicateClient::Version, String] The version of the model to train.
      # @param destination [ReplicateClient::Model, String] The destination model instance or string in "owner/name"
      # format.
      # @param input [Hash] The input data for the training.
      # @param webhook [String, nil] A URL to receive webhook notifications.
      # @param webhook_events_filter [Array, nil] The events to trigger webhook requests.
      #
      # @return [ReplicateClient::Training]
      def create!(owner:, name:, version:, destination:, input:, webhook: nil, webhook_events_filter: nil)
        destination_str = destination.is_a?(ReplicateClient::Model) ? destination.full_name : destination
        version_id = version.is_a?(ReplicateClient::Model::Version) ? version.id : version

        path = "/models/#{owner}/#{name}/versions/#{version_id}/trainings"
        body = {
          destination: destination_str,
          input: input,
          webhook: webhook,
          webhook_events_filter: webhook_events_filter
        }

        attributes = ReplicateClient.client.post(path, body)
        new(attributes)
      end

      # Create a new training for a specific model.
      #
      # @param model [ReplicateClient::Model, String] The model instance or a string representing the model ID.
      # @param destination [ReplicateClient::Model, String] The destination model or full name in "owner/name" format.
      # @param input [Hash] The input data for the training.
      # @param webhook [String, nil] A URL to receive webhook notifications.
      # @param webhook_events_filter [Array, nil] The events to trigger webhook requests.
      #
      # @return [ReplicateClient::Training]
      def create_for_model!(model:, destination:, input:, webhook: nil, webhook_events_filter: nil)
        model_instance = model.is_a?(ReplicateClient::Model) ? model : ReplicateClient::Model.find(model)
        raise ArgumentError, "Invalid model" unless model_instance

        create!(
          owner: model_instance.owner,
          name: model_instance.name,
          version: model_instance.version_id,
          destination: destination,
          input: input,
          webhook: webhook,
          webhook_events_filter: webhook_events_filter
        )
      end

      # Find a training by id.
      #
      # @param id [String] The id of the training.
      #
      # @return [ReplicateClient::Training]
      def find(id)
        path = build_path(id: id)
        attributes = ReplicateClient.client.get(path)
        new(attributes)
      end

      # Cancel a training.
      #
      # @param id [String] The id of the training.
      #
      # @return [void]
      def cancel!(id)
        path = "#{build_path(id: id)}/cancel"
        ReplicateClient.client.post(path)
      end

      # Build the path for a specific training.
      #
      # @param id [String] The id of the training.
      #
      # @return [String]
      def build_path(id:)
        "#{INDEX_PATH}/#{id}"
      end
    end

    # The unique identifier of the training.
    #
    # @return [String]
    attr_accessor :id

    # The full model name in the format "owner/name".
    #
    # @return [String]
    attr_accessor :model

    # The version ID of the model being trained.
    #
    # @return [String]
    attr_accessor :version

    # The input data provided for the training.
    #
    # @return [Hash]
    attr_accessor :input

    # The current status of the training.
    # Possible values: "starting", "processing", "succeeded", "failed", "canceled".
    #
    # @return [String]
    attr_accessor :status

    # The timestamp when the training was created.
    #
    # @return [String]
    attr_accessor :created_at

    # The timestamp when the training was completed.
    #
    # @return [String, nil]
    attr_accessor :completed_at

    # The logs generated during the training process.
    #
    # @return [String]
    attr_accessor :logs

    # The error message, if any, encountered during the training process.
    #
    # @return [String, nil]
    attr_accessor :error

    # URLs related to the training, such as those for retrieving or canceling it.
    #
    # @return [Hash]
    attr_accessor :urls

    # The output data generated during the training process.
    #
    # @return [Hash, nil]
    attr_accessor :output

    # Initialize a new training instance.
    #
    # @param attributes [Hash] The attributes of the training.
    #
    # @return [ReplicateClient::Training]
    def initialize(attributes)
      reset_attributes(attributes)
    end

    # Check if the training is starting.
    #
    # @return [Boolean]
    def starting?
      status == Status::STARTING
    end

    # Check if the training is processing.
    #
    # @return [Boolean]
    def processing?
      status == Status::PROCESSING
    end

    # Check if the training has succeeded.
    #
    # @return [Boolean]
    def succeeded?
      status == Status::SUCCEEDED
    end

    # Check if the training has failed.
    #
    # @return [Boolean]
    def failed?
      status == Status::FAILED
    end

    # Check if the training was canceled.
    #
    # @return [Boolean]
    def canceled?
      status == Status::CANCELED
    end

    # Cancel the training.
    #
    # @return [void]
    def cancel!
      ReplicateClient::Training.cancel!(id)
    end

    # Reload the training.
    #
    # @return [void]
    def reload!
      attributes = ReplicateClient.client.get(Training.build_path(id: id))
      reset_attributes(attributes)
    end

    private

    # Set the attributes of the training.
    #
    # @param attributes [Hash] The attributes of the training.
    #
    # @return [void]
    def reset_attributes(attributes)
      @id = attributes["id"]
      @model = attributes["model"]
      @version = attributes["version"]
      @input = attributes["input"]
      @status = attributes["status"]
      @created_at = attributes["created_at"]
      @completed_at = attributes["completed_at"]
      @logs = attributes["logs"]
      @error = attributes["error"]
      @urls = attributes["urls"]
      @output = attributes["output"]
    end
  end
end
