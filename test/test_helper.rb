# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "replicate-client"

require "minitest/autorun"

class FakeClient
  attr_reader :configuration

  def initialize(stubs: {}, configuration: ReplicateClient::Configuration.new)
    @stubs = stubs
    @configuration = configuration
  end

  def get(path)
    call(:get, path, nil, {})
  end

  def post(path, payload = {}, headers: {})
    call(:post, path, payload, headers)
  end

  def patch(path, payload = {})
    call(:patch, path, payload, {})
  end

  def delete(path)
    call(:delete, path, nil, {})
  end

  private

  def call(method, path, payload, headers)
    key = [method, path]
    responder = @stubs[key]

    if responder.is_a?(Hash) && responder.key?(:sequence)
      sequence = responder[:sequence]
      raise ReplicateClient::NotFoundError, "No stub remaining for #{method.upcase} #{path}" if sequence.empty?

      next_responder = sequence.shift
      @stubs[key] = { sequence: sequence }
      return dispatch(next_responder, payload, headers)
    end

    raise ReplicateClient::NotFoundError, "No stub for #{method.upcase} #{path}" if responder.nil?

    dispatch(responder, payload, headers)
  end

  def dispatch(responder, payload, headers)
    if responder.respond_to?(:call)
      responder.call(payload, headers)
    else
      responder
    end
  end
end
