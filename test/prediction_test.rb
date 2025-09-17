# frozen_string_literal: true

require "test_helper"

class PredictionTest < Minitest::Test
  def sample_prediction(attrs = {})
    {
      "id" => "pred-1",
      "version" => "v1",
      "model" => "acme/widget",
      "input" => { "text" => "hello" },
      "output" => nil,
      "error" => nil,
      "status" => ReplicateClient::Prediction::Status::STARTING,
      "created_at" => Time.now.utc.iso8601,
      "data_removed" => nil,
      "started_at" => nil,
      "completed_at" => nil,
      "metrics" => {},
      "urls" => { "get" => "https://replicate.com/p/pred-1" },
      "logs" => ""
    }.merge(attrs)
  end

  def test_create_prediction_for_version
    stubs = {
      [:post, "/predictions"] => lambda { |payload, headers|
        assert_equal "v1", payload[:version]
        assert_equal({ text: "hi" }, payload[:input])
        assert_equal({}, headers)
        sample_prediction("id" => "p1")
      }
    }
    client = FakeClient.new(stubs: stubs)

    pred = ReplicateClient::Prediction.create!(version: "v1", input: { text: "hi" }, client: client)
    assert_equal "p1", pred.id
    assert pred.starting?
  end

  def test_create_prediction_sync_sets_prefer_wait_header
    stubs = {
      [:post, "/predictions"] => lambda { |_payload, headers|
        assert_equal({ "Prefer" => "wait" }, headers)
        sample_prediction("id" => "p2")
      }
    }
    client = FakeClient.new(stubs: stubs)

    pred = ReplicateClient::Prediction.create!(version: "v1", input: { text: "hi" }, sync: true, client: client)
    assert_equal "p2", pred.id
  end

  def test_create_for_deployment
    stubs = {
      [:post, "/deployments/acme/serve/predictions"] => sample_prediction("id" => "p3")
    }
    client = FakeClient.new(stubs: stubs)

    pred = ReplicateClient::Prediction.create_for_deployment!(deployment: "acme/serve", input: { text: "yo" },
                                                              client: client)
    assert_equal "p3", pred.id
  end

  def test_create_for_official_model
    stubs = {
      [:post, "/models/acme/widget/predictions"] => sample_prediction("id" => "p4")
    }
    client = FakeClient.new(stubs: stubs)

    pred = ReplicateClient::Prediction.create_for_official_model!(model: "acme/widget", input: { text: "yo" },
                                                                  client: client)
    assert_equal "p4", pred.id
  end

  def test_find_and_reload_and_cancel
    stubs = {
      [:get, "/predictions/p5"] => { sequence: [
        sample_prediction("id" => "p5", "status" => ReplicateClient::Prediction::Status::PROCESSING),
        sample_prediction("id" => "p5", "status" => ReplicateClient::Prediction::Status::SUCCEEDED)
      ] },
      [:post, "/predictions/p5/cancel"] => {}
    }
    client = FakeClient.new(stubs: stubs)

    pred = ReplicateClient::Prediction.find("p5", client: client)
    assert pred.processing?

    pred.cancel!

    pred.reload!
    assert pred.succeeded?
  end

  def test_status_predicates
    p = ReplicateClient::Prediction.new(sample_prediction("status" => ReplicateClient::Prediction::Status::FAILED))
    assert p.failed?
    refute p.succeeded?
    refute p.canceled?
  end
end
