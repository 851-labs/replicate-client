# ReplicateClient

**🚧 This gem is still under development 🚧**

## Installation

Install the gem and add to the application"s Gemfile by executing:

    $ bundle add replicate

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install replicate

## Usage

### Configuration

You can configure the gem by calling the `#configure` method on the `ReplicateClient` module. The method accepts a block with the configuration options.

```ruby
ReplicateClient.configure do |config|
  config.access_token = ENV["REPLICATE_ACCESS_TOKEN"] # Required
  config.uri_base = "https://replicate.app/api/v1" # Optional
  config.request_timeout = 5 # Optional (default: 120)
  config.webhook_url = "https://example.com/replicate/webhook" # Optional
end
```

### Get a model

```ruby
model = ReplicateClient::Model.find("stability-ai/sdxl")
model = ReplicateClient::Model.find_by(owner: "stability-ai", name: "sdxl")
model = ReplicateClient::Model.find_by(owner: "stability-ai", name: "sdxl", version_id: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")
```

### Get a model version

```ruby
version = ReplicateClient::Model::Version.find_by(owner: "stability-ai", name: "sdxl", version_id: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")

model = ReplicateClient::Model.find_by(owner: "stability-ai", name: "sdxl", version_id: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")
version = model.version
```

### Get the latest version of a model

```ruby
model = ReplicateClient::Model.find("stability-ai/sdxl")
version = model.latest_version
```

### Get list of model versions

```ruby
model = ReplicateClient::Model.find("stability-ai/sdxl")
versions = model.versions
```

### Paginate through all models

```ruby
ReplicateClient::Model.auto_paging_each do |model|
  puts model.name
end
```

### Create a prediction

```ruby
version = ReplicateClient::Model::Version.find_by(owner: "stability-ai", name: "sdxl", version_id: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")
prediction = version.create_prediction!(input: { my: "input" })

prediction = version.create_prediction!(input: { my: "input" }, webhook_url: "https://example.com/replicate/webhook")

prediction = version.create_prediction!(input: { my: "input" }, webhook_url: "https://example.com/replicate/webhook", webhook_events_filter: ["start", "completed"])

prediction = ReplicateClient::Prediction.create!(version: version, input: { my: "input" })

prediction = ReplicateClient::Prediction.create!(version: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc", input: { my: "input" })

deployment = ReplicateClient::Deployment.find("851-labs/my-deployment")
prediction = deployment.create_prediction!(input: { my: "input" })

model = ReplicateClient::Model.find("stability-ai/sdxl")
prediction = model.create_prediction!(input: { my: "input" })

prediction = ReplicateClient::Prediction.create_for_official_model!(model: "stability-ai/sdxl", input: { my: "input" })
```

### Get a prediction

```ruby
prediction = ReplicateClient::Prediction.find("7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")

prediction = ReplicateClient::Prediction.find_by(id: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")

prediction = ReplicateClient::Prediction.find_by!(id: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")
```

### Reload a resource

```ruby
model = ReplicateClient::Model.find("stability-ai/sdxl")
model.reload!

version = ReplicateClient::Model::Version.find_by(owner: "stability-ai", name: "sdxl", version_id: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")
version.reload!

prediction = ReplicateClient::Prediction.find("7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")
prediction.reload!
```

### Delete a resource

```ruby
model = ReplicateClient::Model.find("stability-ai/sdxl")
model.delete!
```

### Get available hardware

```ruby
hardware = ReplicateClient::Hardware.all
```

### Create a deployment

```ruby
deployment = ReplicateClient::Deployment.create!(name: "851-deployment", model: "stability-ai/sdxl", hardware: "gpu-t4", min_instances: 1, max_instances: 1)

model = ReplicateClient::Model.find("stability-ai/sdxl")
deployment = ReplicateClient::Deployment.create!(name: "851-deployment", model: model, hardware: "gpu-t4", min_instances: 1, max_instances: 1)

hardware = ReplicateClient::Hardware.all.first
deployment = ReplicateClient::Deployment.create!(name: "851-deployment", model: model, hardware: hardware, min_instances: 1, max_instances: 1)
```

### Get a deployment

```ruby
deployment = ReplicateClient::Deployment.find("851-labs/my-deployment")

deployment = ReplicateClient::Deployment.find_by(owner: "851-labs", name: "my-deployment")

deployment = ReplicateClient::Deployment.find_by!(owner: "851-labs", name: "my-deployment")
```

### Paginate through all deployments

```ruby
ReplicateClient::Deployment.auto_paging_each do |deployment|
  puts deployment.name
end
```

### Create a training

```ruby
training = ReplicateClient::Training.create!(owner: "851-labs", name: "my-training", version: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc", destination: "851-labs/my-new-model", input: {})

sdxl = ReplicateClient::Model::Version.find_by(owner: "stability-ai", name: "sdxl", version_id: "7762fd07cf82c948538e41f63f77d685e02b063e37e496e96eefd46c929f9bdc")
destination_model = ReplicateClient::Model.find("851-labs/my-new-model")
training = ReplicateClient::Training.create!(owner: "851-labs", name: "my-training", version: version, destination: destination_model, input: {})

sdxl = ReplicateClient::Model.find("stability-ai/sdxl")
destination_model = ReplicateClient::Model.find("851-labs/my-new-model")
training = ReplicateClient::Training.create_for_model!(model: sdxl, destination: destination_model, input: {})
```

### Get a training

```ruby
training = ReplicateClient::Training.find("b3kgfb2y9nrm00chdnkaam2dvz")
```

### Paginate through all trainings

```ruby
ReplicateClient::Training.auto_paging_each do |training|
  puts training.name
end
```

### Cancel a training

```ruby
training = ReplicateClient::Training.find("b3kgfb2y9nrm00chdnkaam2dvz")
training.cancel!
```

## Warning

Official models will not have vesions. The version id will be nil.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

