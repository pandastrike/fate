task "build" do
  sh "gem build ./fate.gemspec"
end

task "clean" do
  FileList["fate-*.gem"].each do |file|
    rm file
  end
end
