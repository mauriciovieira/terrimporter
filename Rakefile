require 'bundler'
require 'rake'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

#todo this is wrong!
require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "terrimporter #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


namespace :version do

  namespace :bump do
    desc "Bump major version"
    task :major do
      bump_version :major
    end

    desc "Bump minor version"
    task :minor do
      bump_version :minor
    end

    desc "Bump patch version"
    task :patch do
      bump_version :patch
    end
  end

  def bump_version(version_to_bump)
    version = version?
    case version_to_bump
      when :major
        version[:major] = version[:major].to_i + 1
      when :minor
        version[:minor] = version[:minor].to_1 + 1
      when :patch
        version[:patch] = version[:patch].to_i + 1
    end
    write_version(version)
  end

  def version_file_path
    File.join(File.dirname(__FILE__), 'lib', 'terrimporter', 'version.rb')
  end

  def version?
    pattern = /(\d+).(\d+).(\d+)/
    version = nil
    version_file = File.read(version_file_path)
    version_file.scan(pattern) do |match|
      version = {:major => match[0], :minor => match[1], :patch => match[2]}
    end
    version
  end

  def write_version(version={})
    version_rb = %Q{
module TerrImporter
  VERSION = "#{version[:major]}.#{version[:minor]}.#{version[:patch]}"
end
}
    File.open(version_file_path, 'w') {|f| f.write(version_rb)}
  end


end


