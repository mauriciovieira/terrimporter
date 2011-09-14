module TerrImporter

  class DefaultError < StandardError
  end

  class ConfigurationError < StandardError
  end

  class ConfigurationMissingError < StandardError
  end

  class Application
    #todo split importer -> subclass from baseimporter into specified css, img, js and module importer classes
    class Importer
      include ImporterHelper
      attr_accessor :options, :config

      def initialize(options = {})
        self.options = options
        self.config = Configuration.new options[:config_file]
        self.config.load_configuration
        @downloader = Downloader.new config['application_url']
      end

      def run
        if options[:all] != nil and options[:all] == true
          LOG.info "Import everything"
          import_js
          import_css
          import_images
          import_modules
        else
          options.each do |option, value|
            if option.to_s =~ /^import_/ and value == true
              LOG.info "Import of #{option.to_s.split('_').last} started"
              self.send option.to_s
            end
          end
        end
      end

      def import_css
        #todo refactor away with metaprogramming
        unless config.mandatory_present?
          config.determine_configuration_values_from_html @downloader.download('')
        end

        unclean_suffix = "_unclean"
        stylesheets = config.stylesheets

        stylesheets.each do |css|
          file_path = File.join(config['stylesheets']['destination_path'], css)
          options = {}
          options[:suffix] = $1 if css =~ /(ie.*).css$/ #add ie option if in array

          source_url = export_path(:css, options)

          @downloader.download(source_url, file_path + unclean_suffix)

          if config.replace_style_strings?
            LOG.debug "CSS line replacements"
            File.open(file_path, 'w') do |d|
              File.open(file_path + unclean_suffix, 'r') do |s|
                lines = s.readlines
                lines.each do |line|
                  d.print replace_stylesheet_lines!(line)
                end
              end
            end
          else
            LOG.debug "Skipping css line replacements"
          end
          LOG.debug "Deleting unclean css files"
          FileUtils.remove file_path + unclean_suffix
        end
      end

      def import_js
        #todo refactor away with metaprogramming
        unless config.mandatory_present?
          config.determine_configuration_values_from_html @downloader.download('')
        end
        destination_path = File.join(config['javascripts']['destination_path'], "base.js")
        js_source_url = export_path :js

        LOG.info "Import base.js from #{js_source_url} to #{destination_path}"

        @downloader.download(js_source_url, destination_path)


        if config.additional_dynamic_javascripts?

          libraries_destination_path = config.libraries_destination_path
          js_libraries = config.dynamic_libraries

          LOG.info "Import libraries from #{config['libraries_server_path']} to #{libraries_destination_path}"

          if config['libraries_server_path'].nil?
            LOG.info "Define 'libraries_server_path' in configuration file"
          else
            js_libraries.each do |lib|
              @downloader.download(File.join(config['libraries_server_path'], lib), File.join(libraries_destination_path, lib))
            end

          end

        end
      end

      def import_images
        #todo refactor away with metaprogramming
        unless config.mandatory_present?
          config.determine_configuration_values_from_html @downloader.download('')
        end
        if config.images?
          LOG.info "Import images"
          config['images'].each do |image|
            image_source_path = File.join(config['image_server_path'], image['server_path'])
            @downloader.batch_download(image_source_path, image['destination_path'], image['file_types'])
          end
        else
          LOG.debug "Skipping image import"
        end
      end

      def import_modules
        #todo refactor away with metaprogramming
        unless config.mandatory_present?
          config.determine_configuration_values_from_html @downloader.download('')
        end
        if config.modules?
          LOG.info "Module import"

          config['modules'].each do |mod|

            name, skin = extract_module_and_skin_name(mod['name'])

            module_source_url = module_path(name, mod['module_template'], skin, mod['template_only'])
            @downloader.download(module_source_url, File.join(mod['destination_path'], mod['name'] + '.html'))
          end
        else
          LOG.debug "Skipping module import"
        end
      end

      def module_path(name, module_template, skin = nil, template = nil)
        skin = '' if skin.nil?
        #todo add not empty check to name and module_template -> most probably in configuration file
        # todo complete!
        #todo refactor export path to be more universal
        export_path = config['application_url'].clone
        #todo moduletemplate missing!
        export_path << "/terrific/module/details/#{name}/#{module_template}/#{skin}/format/module#{"content" if template}"
        export_path
      end

      private

      def export_path(for_what = :js, options={})
        raise DefaultError, "Specify js or css url" unless for_what == :js or for_what == :css
        export_settings = config['export_settings'].clone
        export_settings.merge!(options)
        export_settings['appbaseurl'] = "" if for_what == :css

        export_path = config['export_path'][for_what.to_s].clone
        export_path << '?' << export_settings.map { |k, v| "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}" }.join("&")
        export_path
      end

      def replace_stylesheet_lines!(line)
        config['stylesheets']['replace_strings'].each do |replace|
          replace_line!(line, replace['what'], replace['with'])
        end
        line
      end
    end
  end
end
