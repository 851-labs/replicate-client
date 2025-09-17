# frozen_string_literal: true

require "test_helper"

class WebhookTest < Minitest::Test
  def test_event_constants
    assert_equal "output", ReplicateClient::Webhook::Event::OUTPUT
    assert_equal "start", ReplicateClient::Webhook::Event::START
    assert_equal "logs", ReplicateClient::Webhook::Event::LOGS
    assert_equal "completed", ReplicateClient::Webhook::Event::COMPLETED
  end
end
