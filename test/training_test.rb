# frozen_string_literal: true

require "test_helper"

class TrainingTest < Minitest::Test
  def training_attrs(id: "t1", status: ReplicateClient::Training::Status::STARTING)
    {
      "id" => id,
      "model" => "acme/widget",
      "version" => "v1",
      "input" => { "input_images" => "https://example.com/train.zip" },
      "status" => status,
      "created_at" => Time.now.utc.iso8601,
      "completed_at" => nil,
      "started_at" => nil,
      "logs" => "",
      "error" => nil,
      "urls" => { "get" => "https://replicate.com/t/#{id}" },
      "output" => nil,
      "metrics" => nil
    }
  end

  def test_create_training
    stubs = {
      [:post, "/models/acme/widget/versions/v1/trainings"] => training_attrs(id: "t2")
    }
    client = FakeClient.new(stubs: stubs)

    t = ReplicateClient::Training.create!(
      owner: "acme",
      name: "widget",
      version: "v1",
      destination: "acme/widget-trained",
      input: { input_images: "https://example.com/train.zip" },
      client: client
    )

    assert_equal "t2", t.id
    assert t.starting?
  end

  def test_create_for_model_validates_and_delegates
    model_resp = {
      "owner" => "acme",
      "name" => "widget",
      "latest_version" => { "id" => "v3" }
    }

    stubs = {
      [:get, "/models/acme/widget"] => model_resp,
      [:post,
       "/models/acme/widget/versions/v3/trainings"] => training_attrs(
         id: "t3",
         status: ReplicateClient::Training::Status::PROCESSING
       )
    }
    client = FakeClient.new(stubs: stubs)

    model = ReplicateClient::Model.find("acme/widget", client: client)
    t = ReplicateClient::Training.create_for_model!(
      model: model,
      destination: "acme/widget-trained",
      input: { input_images: "https://example.com/train.zip" },
      client: client
    )
    assert_equal "t3", t.id
    assert t.processing?
  end

  def test_find_cancel_reload
    stubs = {
      [:get, "/trainings/t4"] => { sequence: [
        training_attrs(id: "t4", status: ReplicateClient::Training::Status::PROCESSING),
        training_attrs(id: "t4", status: ReplicateClient::Training::Status::SUCCEEDED)
      ] },
      [:post, "/trainings/t4/cancel"] => {}
    }
    client = FakeClient.new(stubs: stubs)

    t = ReplicateClient::Training.find("t4", client: client)
    assert t.processing?

    t.cancel!

    t.reload!
    assert t.succeeded?
  end

  def test_auto_paging_each
    page1 = { "results" => [training_attrs(id: "t5")], "next" => "https://api.replicate.com/v1/trainings?cursor=abc" }
    page2 = { "results" => [training_attrs(id: "t6")], "next" => nil }

    stubs = {
      [:get, "/trainings"] => page1,
      [:get, "/trainings?cursor=abc"] => page2
    }

    client = FakeClient.new(stubs: stubs)

    ids = []
    ReplicateClient::Training.auto_paging_each(client: client) { |tr| ids << tr.id }

    assert_equal %w[t5 t6], ids
  end

  def test_status_predicates
    t = ReplicateClient::Training.new(training_attrs(status: ReplicateClient::Training::Status::FAILED))
    assert t.failed?
    refute t.succeeded?
    refute t.canceled?
  end
end
