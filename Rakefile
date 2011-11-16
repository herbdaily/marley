require 'rubygems'
require 'rake'
require 'rake/testtask'

task :default => [:test,:user_test]

x=FileList['test/*_tests.rb']
p x
Rake::TestTask.new(:user_test) do |t|
  t.ruby_opts=['-r test/test_include']
  t.test_files=FileList['test/user_tests.rb']
end
Rake::TestTask.new(:test) do |t|
  t.ruby_opts=['-r test/test_include']
  t.test_files=FileList['test/tagged_messaging_tests.rb']
end

