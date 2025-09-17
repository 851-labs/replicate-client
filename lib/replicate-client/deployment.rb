# frozen_string_literal: true

module ReplicateClient
  class Deployment
    INDEX_PATH = "/deployments"

    class << self
      # List all deployments.
      #
      # @param client [ReplicateClient::Client] The client to use for requests.
      #
      # @yield [ReplicateClient::Deployment] Yields a deployment.
      #
      # @return [void]
      def auto_paging_each(client: ReplicateClient.client, &block)
        cursor = nil

        loop do
          url_params = cursor ? "?cursor=#{cursor}" : ""
          attributes = client.get("#{INDEX_PATH}#{url_params}")

          deployments = attributes["results"].map { |deployment| new(deployment, client: client) }

          deployments.each(&block)

          cursor = attributes["next"] ? URI.decode_www_form(URI.parse(attributes["next"]).query).to_h["cursor"] : nil
          break if cursor.nil?
        end
      end

      # Create a new deployment.
      #
      # @param name [String] The name of the deployment.
      # @param model [ReplicateClient::Model, String] The model identifier in "owner/name" format.
      # @param version_id [String, nil] The version ID of the model.
      # @param hardware [ReplicateClient::Hardware, String] The hardware SKU.
      # @param min_instances [Integer] The minimum number of instances.
      # @param max_instances [Integer] The maximum number of instances.
      # @param client [ReplicateClient::Client] The client to use for requests.
      #
      # @return [ReplicateClient::Deployment]
      def create!(name:, model:, hardware:, min_instances:, max_instances:, version_id: nil,
                  client: ReplicateClient.client)
        model_full_name = model.is_a?(Model) ? model.full_name : model
        hardware_sku = hardware.is_a?(Hardware) ? hardware.sku : hardware
        version = if version_id
                    version_id
                  elsif model.is_a?(Model)
                    model.version_id
                  else
                    Model.find(model, client: client).latest_version.id
                  end

        body = {
          name: name,
          model: model_full_name,
          version: version,
          hardware: hardware_sku,
          min_instances: min_instances,
          max_instances: max_instances
        }

        attributes = client.post(INDEX_PATH, body)
        new(attributes, client: client)
      end

      # Find a deployment by owner and name.
      #
      # @param full_name [String] The full name of the deployment in "owner/name" format.
      # @param client [ReplicateClient::Client] The client to use for requests.
      #
      # @return [ReplicateClient::Deployment]
      def find(full_name, client: ReplicateClient.client)
        path = build_path(**parse_full_name(full_name))
        attributes = client.get(path)
        new(attributes, client: client)
      end

      # Find a deployment by owner and name.
      #
      # @param owner [String] The owner of the deployment.
      # @param name [String] The name of the deployment.
      # @param client [ReplicateClient::Client] The client to use for requests.
      #
      # @return [ReplicateClient::Deployment]
      def find_by!(owner:, name:, client: ReplicateClient.client)
        path = build_path(owner: owner, name: name)
        attributes = client.get(path)
        new(attributes, client: client)
      end

      # Find a deployment by owner and name.
      #
      # @param owner [String] The owner of the deployment.
      # @param name [String] The name of the deployment.
      # @param client [ReplicateClient::Client] The client to use for requests.
      #
      # @return [ReplicateClient::Deployment, nil]
      def find_by(owner:, name:, client: ReplicateClient.client)
        find_by!(owner: owner, name: name, client: client)
      rescue ReplicateClient::NotFoundError
        nil
      end

      # Delete a deployment.
      #
      # @param owner [String] The owner of the deployment.
      # @param name [String] The name of the deployment.
      # @param client [ReplicateClient::Client] The client to use for requests.
      #
      # @return [void]
      def destroy!(owner:, name:, client: ReplicateClient.client)
        path = build_path(owner: owner, name: name)
        client.delete(path)
      end

      # Build the path for a specific deployment.
      #
      # @param owner [String] The owner of the deployment.
      # @param name [String] The name of the deployment.
      #
      # @return [String]
      def build_path(owner:, name:)
        "#{INDEX_PATH}/#{owner}/#{name}"
      end

      # Parse the full name for a deployment.
      #
      # @param full_name [String] The full name of the deployment.
      #
      # @return [Hash]
      def parse_full_name(full_name)
        parts = full_name.split("/")
        { owner: parts[0], name: parts[1] }
      end
    end

    # Attributes for deployment.
    attr_accessor :owner, :name, :current_release

    # The client used to make API requests for this deployment.
    #
    # @return [ReplicateClient::Client]
    attr_accessor :client

    # Initialize a new deployment instance.
    #
    # @param attributes [Hash] The attributes of the deployment.
    # @param client [ReplicateClient::Client] The client to use for requests.
    #
    # @return [ReplicateClient::Deployment]
    def initialize(attributes, client: ReplicateClient.client)
      @client = client
      reset_attributes(attributes)
    end

    # Destroy the deployment.
    #
    # @return [void]
    def destroy!
      self.class.destroy!(owner: owner, name: name, client: @client)
    end

    # Update the deployment.
    #
    # @param hardware [String, nil] The hardware SKU.
    # @param min_instances [Integer, nil] The minimum number of instances.
    # @param max_instances [Integer, nil] The maximum number of instances.
    # @param version [ReplicateClient::Version, String, nil] The version ID of the model.
    #
    # @return [void]
    def update!(hardware: nil, min_instances: nil, max_instances: nil, version: nil)
      version_id = version.is_a?(ReplicateClient::Model::Version) ? version.id : version
      path = self.class.build_path(owner: owner, name: name)
      body = {
        hardware: hardware,
        min_instances: min_instances,
        max_instances: max_instances,
        version: version_id
      }.compact

      attributes = @client.patch(path, body)
      reset_attributes(attributes)
    end

    # Reload the deployment.
    #
    # @return [void]
    def reload!
      attributes = @client.get(path)
      reset_attributes(attributes)
    end

    # Build the path for the deployment.
    #
    # @return [String]
    def path
      self.class.build_path(owner: owner, name: name)
    end

    # Create prediction for the deployment.
    #
    # @param input [Hash] The input for the prediction.
    # @param webhook_url [String, nil] The URL to send webhook events to.
    # @param webhook_events_filter [Array<String>, nil] The events to send to the webhook.
    #
    # @return [ReplicateClient::Prediction]
    def create_prediction!(input, webhook_url: nil, webhook_events_filter: nil)
      Prediction.create_for_deployment!(
        deployment: self,
        input: input,
        webhook_url: webhook_url,
        webhook_events_filter: webhook_events_filter,
        client: @client
      )
    end

    private

    # Set the attributes of the deployment.
    #
    # @param attributes [Hash] The attributes of the deployment.
    #
    # @return [void]
    def reset_attributes(attributes)
      @owner = attributes["owner"]
      @name = attributes["name"]
      @current_release = attributes["current_release"]
    end
  end
end
