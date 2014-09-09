Gem::Specification.new do |s|
  s.name = "fate"
  s.version = "0.3.3"
  s.authors = ["Matthew King"]
  s.email = ["matthew@pandastrike.com"]
  s.homepage = "https://github.com/pandastrike/fate"
  s.summary = "Tool for running and interacting with a multi-process service"

  s.files = %w[
    bin/fate
    LICENSE
    README.md
  ] + Dir["lib/**/*.rb"]
  s.license = "MIT"
  s.require_path = "lib"
  s.executables = "fate"

  s.add_dependency("json", "~> 1.7")
  s.add_dependency("harp", "~> 0.2")
  s.add_dependency("squeeze", "~> 0.2")
  s.add_dependency("term-ansicolor", "~> 1.0")
  s.add_dependency("json-schema", "~> 2.2")

  s.add_development_dependency("starter", "~> 0.2")
  s.add_development_dependency("rspec", "~> 2.12")
end

