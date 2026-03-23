# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
end

desc 'Install rog-helper system-wide'
task :install do
  bindir = ENV['PREFIX'] ? "#{ENV['PREFIX']}/bin" : '/usr/local/bin'
  libdir = ENV['PREFIX'] ? "#{ENV['PREFIX']}/lib/ruby/vendor_ruby" : '/usr/local/lib/ruby/vendor_ruby'

  FileUtils.mkdir_p(bindir)
  FileUtils.mkdir_p(libdir)

  FileUtils.cp('bin/rog-helper', "#{bindir}/rog-helper")
  FileUtils.chmod(0o755, "#{bindir}/rog-helper")

  FileUtils.cp('lib/rog_helper.rb', "#{libdir}/rog_helper.rb")
  FileUtils.cp_r('lib/rog_helper', "#{libdir}/rog_helper")

  puts "Installed rog-helper to #{bindir}"
end

task default: :test