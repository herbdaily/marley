require 'rubygems'
require 'rake'
require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new(:test) do |t|
  t.test_files =FileList['test/*_tests.rb']
end


