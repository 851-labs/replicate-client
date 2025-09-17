# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    # reset global state to avoid bleed between tests
    ReplicateClient.configuration = nil
    # reset memoized client
    ReplicateClient.instance_variable_set(:@client, nil)
  end

  def test_defaults
    cfg = ReplicateClient::Configuration.new
    assert_nil cfg.access_token
    assert_nil cfg.webhook_url
    assert_equal ReplicateClient::Configuration::DEFAULT_URI_BASE, cfg.uri_base
    assert_equal ReplicateClient::Configuration::DEFAULT_REQUEST_TIMEOUT, cfg.request_timeout
  end

  def test_configure_and_client
    ReplicateClient.configure do |c|
      c.access_token = "token"
      c.webhook_url = "https://example.com/webhook"
      c.uri_base = "https://api.replicate.com/v1"
      c.request_timeout = 10
    end

    client = ReplicateClient.client
    assert_equal "token", client.configuration.access_token
    assert_equal "https://example.com/webhook", client.configuration.webhook_url
  end
end
