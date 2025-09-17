# frozen_string_literal: true

require "test_helper"

class HardwareTest < Minitest::Test
  def test_all_lists_hardware
    stubs = {
      [:get, "/hardware"] => [
        { "name" => "CPU", "sku" => "cpu" },
        { "name" => "Nvidia T4 GPU", "sku" => "gpu-t4" }
      ]
    }

    client = FakeClient.new(stubs: stubs)

    hardware = ReplicateClient::Hardware.all(client: client)
    assert_equal 2, hardware.size
    assert_equal "cpu", hardware.first.sku
    assert_equal "CPU", hardware.first.name
    assert_equal "CPU (cpu)", hardware.first.to_s
  end

  def test_find_by_returns_hardware_by_sku
    stubs = {
      [:get, "/hardware"] => [
        { "name" => "CPU", "sku" => "cpu" },
        { "name" => "Nvidia T4 GPU", "sku" => "gpu-t4" }
      ]
    }

    client = FakeClient.new(stubs: stubs)
    hw = ReplicateClient::Hardware.find_by(sku: "gpu-t4", client: client)
    refute_nil hw
    assert_equal "Nvidia T4 GPU", hw.name
    assert_equal "gpu-t4", hw.sku
  end

  def test_find_by_returns_nil_when_not_found
    stubs = { [:get, "/hardware"] => [] }
    client = FakeClient.new(stubs: stubs)
    hw = ReplicateClient::Hardware.find_by(sku: "missing", client: client)
    assert_nil hw
  end
end
