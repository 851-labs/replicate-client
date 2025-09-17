# frozen_string_literal: true

require "test_helper"

class ModelTest < Minitest::Test
  def sample_model_attributes
    {
      "owner" => "acme",
      "name" => "widget",
      "description" => "A test model",
      "visibility" => "public",
      "github_url" => "https://github.com/acme/widget",
      "paper_url" => nil,
      "license_url" => nil,
      "run_count" => 42,
      "cover_image_url" => nil,
      "default_example" => { "input" => { "text" => "hello" } },
      "latest_version" => { "id" => "v_latest" }
    }
  end

  def test_find_and_attributes
    stubs = { [:get, "/models/acme/widget"] => sample_model_attributes }
    client = FakeClient.new(stubs: stubs)

    model = ReplicateClient::Model.find("acme/widget", client: client)

    assert_equal "acme", model.owner
    assert_equal "widget", model.name
    assert_equal "public", model.visibility
    assert model.public?
    refute model.private?
    assert_equal "acme/widget", model.full_name
    assert_equal "v_latest", model.version_id
    assert_equal "v_latest", model.latest_version_id
    assert_equal "/models/acme/widget", model.path
    assert_equal "/models/acme/widget/versions/v_latest", model.version_path
  end

  def test_find_by_returns_nil_on_not_found
    client = FakeClient.new(stubs: {})

    assert_raises(ReplicateClient::NotFoundError) do
      # direct find should raise because no stub => NotFoundError from FakeClient
      ReplicateClient::Model.find("acme/widget", client: client)
    end

    # find_by should swallow NotFoundError and return nil
    assert_nil ReplicateClient::Model.find_by(owner: "acme", name: "widget", client: client)
  end

  def test_create_model
    stubs = {
      [:post, "/models"] => sample_model_attributes
    }
    client = FakeClient.new(stubs: stubs)

    model = ReplicateClient::Model.create!(
      owner: "acme",
      name: "widget",
      description: "A test model",
      visibility: ReplicateClient::Model::Visibility::PUBLIC,
      hardware: "gpu-t4",
      client: client
    )

    assert_equal "acme", model.owner
    assert_equal "widget", model.name
  end

  def test_versions_helpers_use_version_endpoints
    model_attrs = sample_model_attributes
    version_attrs = {
      "id" => "v_latest",
      "created_at" => Time.now.utc.iso8601,
      "cog_version" => "0.8.3",
      "openapi_schema" => { "components" => { "schemas" => {} } }
    }

    stubs = {
      [:get, "/models/acme/widget"] => model_attrs,
      [:get, "/models/acme/widget/versions/v_latest"] => version_attrs,
      [:get, "/models/acme/widget/versions"] => { "results" => [version_attrs], "next" => nil }
    }
    client = FakeClient.new(stubs: stubs)

    model = ReplicateClient::Model.find("acme/widget", client: client)

    assert_equal "v_latest", model.version.id
    assert_equal "v_latest", model.latest_version.id
    assert_equal ["v_latest"], model.versions.map(&:id)
  end

  def test_create_prediction_routes_based_on_version_presence
    # official model endpoint
    client1 = FakeClient.new(
      stubs: {
        [:post, "/models/acme/widget/predictions"] => {
          "id" => "pred1",
          "model" => "acme/widget",
          "version" => "v1",
          "status" => "starting"
        }
      }
    )
    pred = ReplicateClient::Prediction.create_for_official_model!(
      model: "acme/widget",
      input: { text: "hi" },
      client: client1
    )
    assert_equal "pred1", pred.id

    # global predictions endpoint with explicit version
    client2 = FakeClient.new(
      stubs: {
        [:post, "/predictions"] => {
          "id" => "pred2",
          "model" => "acme/widget",
          "version" => "v2",
          "status" => "starting"
        }
      }
    )
    pred2 = ReplicateClient::Prediction.create!(version: "v2", input: { text: "yo" }, client: client2)
    assert_equal "pred2", pred2.id
  end
end
