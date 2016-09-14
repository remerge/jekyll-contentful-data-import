require 'yaml'
require 'jekyll-contentful-data-import/mappers'

module Jekyll
  module Contentful
    class MultiExporter
      DATA_FOLDER = '_data'
      CONTENTFUL_FOLDER = 'contentful'
      SPACES_FOLDER = 'spaces'

      attr_reader :name, :entries, :config

      def initialize(name, entries, config = {})
        @name = name
        @entries = entries
        @config = config
      end

      def run
        # TODO: different spaces won't work
        types_config = config['content_types']

        # TODO: use sync for incremental
        FileUtils.rm_r(collection_directory) rescue nil
        FileUtils.rm_r(data_directory) rescue nil

        entries.group_by { |entry| entry.content_type.id }.each do |content_type, entry_list|
          type_config = types_config[content_type]
          next unless type_config

          if type_config['as_collection']
            write_as_collection(content_type, entry_list, type_config)
          else
            write_as_data(content_type, entry_list, type_config)
          end
        end
      end

      def write_as_collection(content_type, entry_list, type_config)
        destination_directory = File.join(collection_directory, type_config['maps_to'])
        FileUtils.mkdir_p(destination_directory)

        entry_list.each do |entry|
          # get title for filename
          title = entry.public_send(type_config['title_field'])

          # write file
          destination_file = File.join(destination_directory, ::Jekyll::Utils.slugify(title) + '.md')
          File.open(destination_file, 'w') do |file|
            # TODO: ignoring custom mappings for now
            data = ::Jekyll::Contentful::Mappers::Base.mapper_for(entry, {}).map

            # TODO: should this be snake case?
            data['contentType'] = content_type
            file.puts(YAML.dump(data))
            file.puts('---')
          end
        end
      end

      def write_as_data(content_type, entry_list, type_config)
        FileUtils.mkdir_p(data_directory)
        destination_file = File.join(data_directory, type_config['maps_to'] + '.yml')
        File.open(destination_file, 'w') do |file|
          array = entry_list.map do |entry|
            ::Jekyll::Contentful::Mappers::Base.mapper_for(entry, {}).map
          end
          file.write(YAML.dump(array))
        end
      end

      def base_directory
        directory = File.expand_path(Dir.pwd)
        directory = File.join(directory, config['base_path']) if config.key?('base_path')
        directory
      end

      def collection_directory
        File.join(base_directory, '_contentful')
      end

      def data_directory
        File.join(base_directory, DATA_FOLDER, CONTENTFUL_FOLDER)
      end
    end
  end
end
