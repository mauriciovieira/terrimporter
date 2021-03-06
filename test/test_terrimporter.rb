require 'test_helper'

class TestTerrimporter < Test::Unit::TestCase
  include ConfigurationHelper

  def setup
    ENV['TERRIMPORTER_OPTS'] = nil
  end

  def teardown
    File.delete config_file if File.exists? config_file
    File.delete config_file + ".bak" if File.exists? config_file + ".bak"
  end

  should 'build options as a combination form argument options and environment options' do
    ENV['TERRIMPORTER_OPTS'] = "-j"
    arguments = ["testfile", '-c']
    merged_options = TerrImporter::Application.build_options(arguments)
    assert merged_options.include?(:import_js)
    assert merged_options.include?(:import_css)
  end

  should 'merge environment and argument options' do
    ENV['TERRIMPORTER_OPTS'] = '-j -c'
    merged_options = TerrImporter::Application.build_options([''] + ['-i', '--verbose'])
    expected_options = {:application_url => "",
                        :import_css => true,
                        :import_js => true,
                        :import_images => true,
                        :show_help => false,
                        :verbose => true}

    assert_contains merged_options, expected_options
  end


  should 'run the importer with the init command and a non existing configuration file' do
    TerrImporter::Application.run!(["test"], '--init')
    assert File.exists? config_file
  end

  should 'run the importer with the init command and a non existing configuration file' do
    TerrImporter::Application.run!(["test"], '--init replace')
    assert File.exists? config_file
  end

  should 'run the importer with the init command and a non existing configuration file' do
    TerrImporter::Application.run!(["test"], '--init')
    TerrImporter::Application.run!(["test"], '--init', 'backup')
    assert File.exists? config_file
  end

  should 'run the importer with the init command and an existing configuration file, this leads to an error' do
    TerrImporter::Application.run!(["test"], '--init')
    return_code = TerrImporter::Application.run!(["test"], '--init')
    assert return_code == 1
  end

  should 'run the importer with an invalid option, display help and return error code' do
    return_code = TerrImporter::Application.run!(["test"], '--invalidoption')
    assert return_code == 1
  end

  should 'run the importer with an invalid argument, display help and return error code' do
    return_code = TerrImporter::Application.run!(["test"], '--init', 'INVALID')
    assert return_code == 1
  end

  should 'run the importer show help argument, display help and return error code' do
    return_code = TerrImporter::Application.run!(["test"], '--help')
    assert return_code == 1
  end

  should 'run the importer show version and return' do
    return_code = TerrImporter::Application.run!(["test"], '--version')
    assert return_code == 0
    end

  should 'run the importer in verbose mode' do
    return_code = TerrImporter::Application.run!(["test"], '-v')
    assert return_code == 1 #configuration missing because not initialized
  end

  should 'run the importer with the init command and a non existing configuration file' do
    TerrImporter::Application.run!(["http://terrific.url"], '--init')
    return_code = TerrImporter::Application.run!(["http://terrific.url"], '-a') #full run
    assert return_code == 0
  end

  def config_file
    File.join(File.dirname(__FILE__), '..', config_default_name)
  end

end
