require 'contentful'
require 'jekyll-contentful-data-import/multi_exporter'

module Jekyll
  module Contentful
    class Importer
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def run
        spaces.each do |name, options|
          space_client = client(
            options['space'],
            options['access_token'],
            client_options(options.fetch('client_options', {}))
          )

          loaded_entries = []
          entries = space_client.entries(options.fetch('cda_query', {}))
          while !entries.empty?
            loaded_entries += entries.to_a
            entries = entries.next_page(space_client)
          end

          Jekyll::Contentful::MultiExporter.new(name, loaded_entries, options).run
        end
      end

      def spaces
        config['spaces'].map { |space_data| space_data.first }
      end

      def client(space, access_token, options = {})
        options = {
          space: space,
          access_token: access_token,
          dynamic_entries: :auto,
          raise_errors: true
        }.merge(options)

        ::Contentful::Client.new(options)
      end

      private

      def client_options(options)
        options = options.each_with_object({}){|(k,v), memo| memo[k.to_sym] = v; memo}
        options.delete(:dynamic_entries)
        options.delete(:raise_errors)
        options
      end
    end
  end
end
