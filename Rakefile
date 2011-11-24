require 'rubygems'
require 'rake'
require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new(:test) do |t|
  t.ruby_opts=['-r test/test_include']
  t.test_files=FileList['test/*_tests.rb']
end

Rake::TestTask.new(:unit) do |t|
  t.test_files=FileList['test/*_unit.rb']
end
