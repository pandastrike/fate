
Example of a service spec:

```json
{
  "commands": {
    "redis": "redis-server ./redis.conf",
    "mongod": "mongod run --quiet",
    "http_server": "./bin/server -h 127.0.0.1 -p 8080",
  }
}

```

Command line usage:

    fate_control -c service.json



Usage within Ruby:

```ruby
require "fate_control"
require "json"
string = File.read("service.json")
configuration = JSON.parse(string, :symbolize_names => true)
spawner = Fate.new(configuration, :service_log => "logs/service.log")

spawner.start do
  # run your tests
  # when this block finishes evaluation, Fate shuts down the service
end
```
