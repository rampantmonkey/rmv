require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib/menagerie_generator'
  t.test_files = FileList['test/lib/menagerie_generator/*_test.rb']
  t.verbose = true
end

task default: :test
