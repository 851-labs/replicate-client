# frozen_string_literal: true

require "test_helper"

class DeploymentTest < Minitest::Test
  def deployment_attrs(owner: "acme", name: "serve")
    {
      "owner" => owner,
      "name" => name,
      "current_release" => { "version" => "v1" }
    }
  end

  def test_auto_paging_each
    page1 = { "results" => [deployment_attrs(name: "serve1")], "next" => "https://api.replicate.com/v1/deployments?cursor=abc" }
    page2 = { "results" => [deployment_attrs(name: "serve2")], "next" => nil }

    stubs = {
      [:get, "/deployments"] => page1,
      [:get, "/deployments?cursor=abc"] => page2
    }

    client = FakeClient.new(stubs: stubs)

    names = []
    ReplicateClient::Deployment.auto_paging_each(client: client) { |d| names << d.name }

    assert_equal %w[serve1 serve2], names
  end

  def test_create_find_update_reload_destroy
    stubs = {
      [:post, "/deployments"] => deployment_attrs,
      [:get, "/deployments/acme/serve"] => { sequence: [deployment_attrs, deployment_attrs] },
      [:patch, "/deployments/acme/serve"] => deployment_attrs(owner: "acme", name: "serve"),
      [:delete, "/deployments/acme/serve"] => {}
    }
    client = FakeClient.new(stubs: stubs)

    d = ReplicateClient::Deployment.create!(
      name: "serve",
      model: "acme/widget",
      version_id: "v1",
      hardware: "gpu-t4",
      min_instances: 0,
      max_instances: 1,
      client: client
    )

    assert_equal "acme", d.owner
    assert_equal "serve", d.name

    found = ReplicateClient::Deployment.find("acme/serve", client: client)
    assert_equal "serve", found.name

    found.update!(hardware: "gpu-a40-small")
    assert_equal "serve", found.name

    found.reload!
    assert_equal "serve", found.name

    # should not raise
    found.destroy!
  end

  def test_find_by_and_find_by_bang
    stubs = {
      [:get, "/deployments/acme/serve"] => deployment_attrs
    }
    client = FakeClient.new(stubs: stubs)

    d = ReplicateClient::Deployment.find_by(owner: "acme", name: "serve", client: client)
    refute_nil d

    d2 = ReplicateClient::Deployment.find_by!(owner: "acme", name: "serve", client: client)
    refute_nil d2

    # when not found, find_by returns nil
    client2 = FakeClient.new(stubs: {})
    assert_nil ReplicateClient::Deployment.find_by(owner: "acme", name: "missing", client: client2)
  end

  def test_create_prediction_delegates
    stubs = {
      [:post, "/deployments/acme/serve/predictions"] => {
        "id" => "p9",
        "model" => "acme/widget",
        "version" => "v1",
        "status" => "starting"
      }
    }
    client = FakeClient.new(stubs: stubs)

    d = ReplicateClient::Deployment.new(deployment_attrs, client: client)
    pred = d.create_prediction!({ text: "hi" })

    assert_equal "p9", pred.id
  end
end
