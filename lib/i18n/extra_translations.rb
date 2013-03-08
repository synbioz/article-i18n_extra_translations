require 'i18n'
require 'i18n/exceptions'

dirname = File.dirname(__FILE__)

module I18n
  class ExtraTranslations
    autoload :Store, "#{dirname}/extra_translations/store.rb"
    autoload :SimpleExtension, "#{dirname}/extra_translations/simple_extension.rb"

    class << self
      # An ExtraTranslations::Store will be availaible everywhere
      attr_writer :extra_translations
      def extra_translations
        @extra_translations ||= ExtraTranslations::Store.new
      end

      # Allow the user to focus its search on a specific locale
      attr_writer :locale
      def locale
        @locale ||= I18n.default_locale
      end

      # Returns all the unused translation of some files and
      # groups the results by filename.
      def unused_translations(filenames=nil)
        filenames ||= ["./config/locales/#{locale}.yml"]
        filenames.inject({}) do |memo, filename|
          data = YAML.load_file(filename)
          keys = all_keys_from(data, [])
          memo[filename] = keys.select{|keys| !extra_translations.used?(keys)}
          memo[filename].map!{|keys| keys.join('.')}
          memo
        end
      end

      # Returns all the translate keys that throw an error
      def missing_translations
        keys = all_keys_from(extra_translations, [], []) do |keys, _|
          !extra_translations.used?(keys)
        end
        keys.map{ |keys| keys.join('.') }
      end

      protected

        # Build a list of translation paths
        def all_keys_from(data, memo, stack=[], &filter)
          if data.kind_of? Hash
            keys = data.inject([]) do |m, (k, v)|
              m + all_keys_from(v, [], stack.dup << k, &filter)
            end
            memo + keys
          elsif filter.nil? || filter.call(stack, data)
            memo << stack
          else
            memo
          end
        end
    end
  end

  Backend::Simple.include ExtraTranslations::SimpleExtension
end
