# frozen_string_literal: true

require_relative "lib/replicate-client/version"

Gem::Specification.new do |spec|
  spec.name = "replicate-client"
  spec.version = ReplicateClient::VERSION
  spec.authors = ["Dylan Player"]
  spec.email = ["dylan@851.sh"]

  spec.summary = "Ruby client for Replicate API."
  spec.homepage = "https://github.com/851-labs/replicate"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.license = "MIT"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("faraday", ">= 1")
  spec.metadata["rubygems_mfa_required"] = "true"
end
