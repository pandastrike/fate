Gem::Specification.new do |s|
  s.name = "fate"
  s.version = "0.2.20"
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
  s.add_dependency("harp", ">=0.2.10")
  s.add_dependency("squeeze", ">=0.2.0")
  s.add_dependency("term-ansicolor", ">=1.0.0")
  s.add_dependency("json-schema", ">=1.0.10")
  s.add_development_dependency("starter", ">= 0.1.7")
  s.add_development_dependency("rspec", ">= 2.12.0")
end

