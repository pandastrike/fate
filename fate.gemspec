Gem::Specification.new do |s|
  s.name = "fate"
  s.version = "0.2.13"
  s.authors = ["Matthew King"]
  s.homepage = "https://github.com/automatthew/fate"
  s.summary = "Tool for running and interacting with a multi-process service"

  s.files = %w[
    bin/fate
    LICENSE
    README.md
  ] + Dir["lib/**/*.rb"]
  s.require_path = "lib"
  s.executables = "fate"

  s.add_dependency("json", ">=1.7.5")
  s.add_dependency("harp", "0.2.7")
  s.add_dependency("squeeze", ">=0.2.0")
  s.add_dependency("term-ansicolor", ">=1.0.0")
  s.add_dependency("json-schema", ">=1.0.10")
end

