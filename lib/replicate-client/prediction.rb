# frozen_string_literal: true

module ReplicateClient
  class Prediction
    INDEX_PATH = "/predictions"

    module Status
      STARTING   = "starting"
      PROCESSING = "processing"
      SUCCEEDED  = "succeeded"
      FAILED     = "failed"
      CANCELED   = "canceled"
    end

    class << self
      # Create a new prediction for a version.
      #
      # @param version [String, ReplicateClient::Version] The version of the model to use for the prediction.
      # @param input [Hash] The input data for the prediction.
      # @param webhook_url [String] The URL to send webhook events to.
      # @param webhook_events_filter [Array<Symbol>] The events to send to the webhook.
      #
      # @return [ReplicateClient::Prediction]
      def create!(version:, input:, webhook_url: nil, webhook_events_filter: nil)
        args = {
          version: version.is_a?(Model::Version) ? version.id : version,
          input: input,
          webhook: webhook_url || ReplicateClient.configuration.webhook_url,
          webhook_events_filter: webhook_events_filter&.map(&:to_s)
        }

        prediction = ReplicateClient.client.post(INDEX_PATH, args)

        new(prediction)
      end

      # Create a new prediction for a deployment.
      #
      # @param deployment [String, ReplicateClient::Deployment] The deployment to use for the prediction.
      # @param input [Hash] The input data for the prediction.
      # @param webhook_url [String] The URL to send webhook events to.
      # @param webhook_events_filter [Array<Symbol>] The events to send to the webhook.
      #
      # @return [ReplicateClient::Prediction]
      def create_for_deployment!(deployment:, input:, webhook_url: nil, webhook_events_filter: nil)
        args = {
          input: input,
          webhook: webhook_url || ReplicateClient.configuration.webhook_url,
          webhook_events_filter: webhook_events_filter&.map(&:to_s)
        }

        prediction = ReplicateClient.client.post("#{deployment.path}#{INDEX_PATH}", args)

        new(prediction)
      end

      # Create a new prediction for a model.
      #
      # @param model [String, ReplicateClient::Model] The model to use for the prediction.
      # @param input [Hash] The input data for the prediction.
      # @param webhook_url [String] The URL to send webhook events to.
      # @param webhook_events_filter [Array<Symbol>] The events to send to the webhook.
      #
      # @return [ReplicateClient::Prediction]
      def create_for_official_model!(model:, input:, webhook_url: nil, webhook_events_filter: nil)
        model_path = model.is_a?(Model) ? model.path : Model.build_path(**Model.parse_model_name(model))

        args = {
          input: input,
          webhook: webhook_url || ReplicateClient.configuration.webhook_url,
          webhook_events_filter: webhook_events_filter&.map(&:to_s)
        }

        prediction = ReplicateClient.client.post("#{model_path}#{INDEX_PATH}", args)

        new(prediction)
      end

      # Find a prediction.
      #
      # @param id [String] The ID of the prediction.
      #
      # @return [ReplicateClient::Prediction]
      def find(id)
        attributes = ReplicateClient.client.get(build_path(id))
        new(attributes)
      end

      # Find a prediction.
      #
      # @param id [String] The ID of the prediction.
      #
      # @return [ReplicateClient::Prediction]
      def find_by!(id:)
        find(id)
      end

      # Find a prediction.
      #
      # @param id [String] The ID of the prediction.
      #
      # @return [ReplicateClient::Prediction]
      def find_by(id:)
        find_by!(id: id)
      rescue ReplicateClient::NotFoundError
        nil
      end

      # Build the path for the prediction.
      #
      # @param id [String] The ID of the prediction.
      #
      # @return [String]
      def build_path(id)
        "#{INDEX_PATH}/#{id}"
      end

      # Cancel a prediction.
      #
      # @param id [String] The ID of the prediction.
      #
      # @return [void]
      def cancel!(id)
        ReplicateClient.client.post("#{build_path(id)}/cancel")
      end
    end

    # The ID of the prediction.
    #
    # @return [String]
    attr_accessor :id

    # The version of the model used for the prediction.
    #
    # @return [String]
    attr_accessor :version_id

    # The model used for the prediction.
    #
    # @return [String]
    attr_accessor :model_name

    # The input data for the prediction.
    #
    # @return [Hash]
    attr_accessor :input

    # The output data for the prediction.
    #
    # @return [Hash]
    attr_accessor :output

    # The error message for the prediction.
    #
    # @return [String]
    attr_accessor :error

    # The status of the prediction.
    #
    # @return [String]
    attr_accessor :status

    # The date the prediction was created.
    #
    # @return [Time]
    attr_accessor :created_at

    # The date the prediction was removed.
    #
    # @return [Time]
    attr_accessor :data_removed

    # The date the prediction was started.
    #
    # @return [Time]
    attr_accessor :started_at

    # The date the prediction was completed.
    #
    # @return [Time]
    attr_accessor :completed_at

    # The metrics for the prediction.
    #
    # @return [Hash]
    attr_accessor :metrics

    # The URLs for the prediction.
    #
    # @return [Hash]
    attr_accessor :urls

    # The logs for the prediction.
    #
    # @return [String]
    attr_accessor :logs

    def initialize(attributes)
      reset_attributes(attributes)
    end

    # Reload the prediction.
    #
    # @return [ReplicateClient::Prediction]
    def reload!
      attributes = ReplicateClient.client.get(Prediction.build_path(@id))
      reset_attributes(attributes)
    end

    # The model used for the prediction.
    #
    # @return [ReplicateClient::Model]
    def model
      @model ||= Model.find(@model_name, version_id: @version_id)
    end

    # The version of the model used for the prediction.
    #
    # @return [ReplicateClient::Model::Version]
    def version
      @version ||= model.version
    end

    # Cancel the prediction.
    #
    # @return [void]
    def cancel!
      Prediction.cancel!(id)
    end

    # Check if the prediction is succeeded.
    #
    # @return [Boolean]
    def succeeded?
      status == Status::SUCCEEDED
    end

    # Check if the prediction is failed.
    #
    # @return [Boolean]
    def failed?
      status == Status::FAILED
    end

    # Check if the prediction is canceled.
    #
    # @return [Boolean]
    def canceled?
      status == Status::CANCELED
    end

    # Check if the prediction is starting.
    #
    # @return [Boolean]
    def starting?
      status == Status::STARTING
    end

    # Check if the prediction is processing.
    #
    # @return [Boolean]
    def processing?
      status == Status::PROCESSING
    end

    private

    # Set the attributes of the prediction.
    #
    # @param attributes [Hash] The attributes of the prediction.
    #
    # @return [void]
    def reset_attributes(attributes)
      @id = attributes["id"]
      @version_id = attributes["version"]
      @model_name = attributes["model"]
      @input = attributes["input"]
      @output = attributes["output"]
      @error = attributes["error"]
      @status = attributes["status"]
      @created_at = attributes["created_at"]
      @data_removed = attributes["data_removed"]
      @started_at = attributes["started_at"]
      @completed_at = attributes["completed_at"]
      @metrics = attributes["metrics"]
      @urls = attributes["urls"]
      @logs = attributes["logs"]

      @model = nil
      @version = nil
    end
  end
end
