# frozen_string_literal: true

require "test_helper"

class ModelVersionTest < Minitest::Test
  def version_attrs(id: "v1")
    {
      "id" => id,
      "created_at" => Time.now.utc.iso8601,
      "cog_version" => "0.8.3",
      "openapi_schema" => {
        "components" => {
          "schemas" => {
            "PredictionRequest" => {
              "properties" => {
                "input" => { "$ref" => "#/components/schemas/InputSchema" }
              }
            },
            "TrainingRequest" => {
              "properties" => {
                "input" => { "$ref" => "#/components/schemas/TrainInput" }
              }
            },
            "InputSchema" => {
              "type" => "object",
              "properties" => { "text" => { "type" => "string" } }
            },
            "TrainInput" => {
              "type" => "object",
              "properties" => { "images" => { "type" => "string", "format" => "uri" } }
            }
          }
        }
      }
    }
  end

  def test_find_by_bang
    stubs = { [:get, "/models/acme/widget/versions/v1"] => version_attrs }
    client = FakeClient.new(stubs: stubs)

    version = ReplicateClient::Model::Version.find_by!(owner: "acme", name: "widget", version_id: "v1", client: client)
    assert_equal "v1", version.id
    assert_equal "0.8.3", version.cog_version
    assert_kind_of Hash, version.openapi_schema
  end

  def test_where_and_auto_paging_each
    page1 = { "results" => [version_attrs(id: "v1")], "next" => "https://api.replicate.com/v1/models/acme/widget/versions?cursor=abc" }
    page2 = { "results" => [version_attrs(id: "v2")], "next" => nil }

    stubs = {
      [:get, "/models/acme/widget/versions"] => page1,
      [:get, "/models/acme/widget/versions?cursor=abc"] => page2
    }

    client = FakeClient.new(stubs: stubs)

    versions = ReplicateClient::Model::Version.where(owner: "acme", name: "widget", client: client)
    assert_equal %w[v1 v2], versions.map(&:id)
  end

  def test_schema_helpers_resolve_refs
    stubs = { [:get, "/models/acme/widget/versions/v1"] => version_attrs }
    client = FakeClient.new(stubs: stubs)

    version = ReplicateClient::Model::Version.find_by!(owner: "acme", name: "widget", version_id: "v1", client: client)

    pred_schema = version.prediction_input_schema
    train_schema = version.training_input_schema

    assert_equal "object", pred_schema["type"]
    assert_equal "object", train_schema["type"]
    assert pred_schema["properties"].key?("text")
    assert train_schema["properties"].key?("images")
  end

  def test_create_prediction_from_version
    stubs = {
      [:post, "/predictions"] => { "id" => "p123", "model" => "acme/widget", "version" => "v1", "status" => "starting" }
    }
    client = FakeClient.new(stubs: stubs)

    version = ReplicateClient::Model::Version.new(version_attrs, client: client)
    pred = version.create_prediction!(input: { text: "hello" })

    assert_equal "p123", pred.id
  end
end
