
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

    spawn_control -c service.json



Usage within Ruby:

```ruby
require "spawn_control"
require "json"
string = File.read("service.json")
configuration = JSON.parse(string, :symbolize_names => true)
spawner = SpawnControl.new(configuration, :service_log => "logs/service.log")

spawner.start do
  # run your tests
end
```
