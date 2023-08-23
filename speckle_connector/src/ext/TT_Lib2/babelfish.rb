#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require_relative 'core.rb'

# Translation dictionary. Pass strings through the +translate+ or +tr+ method
# to translate strings to the language given in to the last +load+ call.
#
# Silently eats errors and pass through the original string if a translation
# cannot be made.
#
#   module MyPlugin
#
#    # Assigning the instance to a constant makes it into
#    # a easy to use shorthand that works in any sub-modules/classes.
#    S = TT::Babelfish.new( l10n_path )
#
#    def self.init
#      S.load( 'fr' )
#    end
#
#    def self.foo
#      puts S.tr( 'Hello World' )
#    end
#
#  end # module
#
#
# @since 2.5.0
module SpeckleConnector
  class TT::Babelfish

    # @since 2.5.0
    attr_reader( :l10n, :default_l10n, :path, :file_ex )

    # @param [String] l10n_path The path where the translation files are located.
    # @param [String] default_l10n The source translation code.
    # @param [String] file_ex The file extension of the translation files.
    #
    # @since 2.5.0
    def initialize(l10n_path, default_l10n = 'en', file_ex = 'l10n')
      @file_ex = file_ex.dup
      @l10n = default_l10n.dup
      @default_l10n = default_l10n.dup
      @dictionary = {}
      @metadata = {} # (!) Default data

      path = File.expand_path( l10n_path )
      unless File.exist?( path )
        raise( ArgumentError, 'Path does not exist.' )
      end
      @path = path
    end


    # @return [String]
    # @since 2.5.0
    def inspect
      if @metadata
        name = @metadata['name']
        size = @dictionary.size
        "<#{self.class}:#{@l10n} - Speaks #{size} phrases in #{name}>"
      else
        "<#{self.class}:#{@l10n}>"
      end
    end


    # @return [Hash] A copy of the current translation dictionary.
    # @since 2.5.0
    def dictionary
      @dictionary.dup
    end


    # @return [Hash] A copy of the current translation dictionary.
    # @since 2.5.0
    def metadata
      @metadata.dup
    end


    # Loads a translation dictionary.
    #
    # @param [String] l10n must represent the base name of a .l10n file in the
    #                 language folder.
    #
    # @return [Boolean] +true+ on success, +false+ on failure.
    # @since 2.5.0
    def load(l10n)
      # Special case for default language.
      if l10n == @default_l10n
        @l10n = @default_l10n
        @metadata.clear # (!) Default data
        @dictionary.clear
        return true
      end
      # Work out the filename and ensure it exists.
      filename = File.join(@path, "#{l10n}.#{@file_ex}")
      unless File.exists?(filename)
        puts "Babelfish - Failed to load l10n: #{l10n} (#{filename}). No such file."
        return false
      end
      # Open the language file and parse the content. Unicode Regex ensures that
      # UTF-8 files are parsed properly.
      #
      # Using a proxy hash prevents a failed appempt of loading a translation
      # file from ruining the existing translation hash.
      #
      # Garbage data - data that doesn't match the expected format is ignored.
      dictionary = {}
      metadata = {}
      File.open(filename, 'r') { |file|
        metadata = read_metadata(file)
        unless metadata
          puts "Babelfish - Failed to load l10n: #{l10n} (#{filename}). Invalid data."
          return false
        end
        file.each { |line|
          next if line.match(/^\s*#/u) # Ignore comments
          next if line.match(/^\s*$/u) # Ignore empty lines
          if match = line.match(/^\s*"(.*)"\s*=\s*"(.*)"\s*$/u)
            dictionary[ match[1] ] = match[2]
          end
        }
      }
      @l10n = l10n.dup
      @metadata = metadata
      @dictionary = dictionary
      true
    end


    # Looks up the string and returns a translated string.
    # If no translated string exists, the original is returned.
    #
    # Silently outputs any errors to the console and returns the original
    # string.
    #
    # @param [String] string
    # @param [Array] args
    #
    # @return [String]
    # @since 2.5.0
    def translate(string, *args)
      translated = @dictionary[string] || string
      sprintf(translated, *args)
    rescue => e
      p e.message
      puts e.backtrace.join("\n")
      sprintf(string, *args)
    end
    alias :tr :translate


    # Used to handle singluar vs plural form.
    #
    # When +expression+ is a boolean, +true+ represent singular.
    #
    # @param [Numeric, Enumerable, Boolean] expression
    # @param [String] singular
    # @param [String] multiple
    # @param [Array] args
    #
    # @return [String]
    # @since 2.12.0
    def plural(expression, singular, multiple, *args)
      single = false
      case expression
      when Numeric
        single = expression.to_i == 1
      when Enumerable
        [:size, :length, :count].each { |symbol|
          single = expression.send(symbol) == 1 if expression.respond_to?(symbol)
        }
      else
        single = !!expression
      end
      string = single ? singular : multiple
      translate(string, *args)
    end
    alias :pl :plural


    # Utility accessor to return a string without arguments.
    #
    # @param [String] string
    #
    # @return [String]
    # @since 2.12.0
    def [](string)
      translate(string)
    end


    # Iterates the language folder for .l10n files and extracts the required
    # display name in the first line of the file.
    #
    # Returns a hash of all the languages availible. The key is the translation
    # code and the value is a hash with meta data.
    #
    # The meta data contains one required key: 'name' and optionally 'author'
    # and/or 'contact'.
    #
    #  {
    #    'no' => {
    #      'name' => '...'
    #    },
    #    'fr' => {
    #      'name' => '...',
    #      'author' => '...',
    #      'contact' => '...'
    #    }
    #  }
    #
    # How to get an array of availible language codes:
    #  codes = babelfish.translations.keys
    #
    # Silently eats errors and output any errors or warnings to the console.
    #
    # @return [Hash]
    # @since 2.5.0
    def translations
      lang = {}
      file_filter = File.join(@path, "*.#{@file_ex}")
      Dir.glob( file_filter ) { |filename|
        lang_code = File.basename(filename, ".#{@file_ex}")
        File.open(filename, 'r') { |file|
          # UTF-8 files might have a BOM mark, account for this.
          metadata = read_metadata(file)
          if metadata
            lang[lang_code] = metadata
          else
            puts "WARNING: No @title in #{filename}"
          end
        }
      }
      lang # (?) This method appears to return false unless this is here...
    rescue => e
      p e.message
      puts e.backtrace.join("\n")
    ensure
      lang
    end


    # Try to pick a language based on the Sketchup locale.
    #
    # 1. Tries exact matches.
    # 2. Tries to find by language code, (if SU locale is en-GB) it tries to find
    #    "en.l10n".
    # 3. Tries to find a similar dialect. (if SU locale is en-GB) it will consider
    #    "en-US.l10n" a match.
    #
    # (!)
    # Norwegian is nn-NO and nb-NO, no
    # This appear to be different from how English system works.
    #
    # http://msdn.microsoft.com/en-us/library/system.globalization.cultureinfo%28VS.80%29.aspx
    #
    # @return [String]
    # @since 2.5.0
    def guess_l10n
      su_locale = Sketchup.get_locale.downcase
      # Extract list of languages availible
      file_filter = File.join( @path, "*.#{@file_ex}" )
      languages = Dir.glob( file_filter ).map { |filename|
        File.basename(filename, ".#{@file_ex}").downcase
      }
      # First search for exact match
      for lang_code in languages
        return lang_code if lang_code == su_locale
      end
      # Search for partial match - language code
      su_country = su_locale.split('-').first
      for lang_code in languages
        return lang_code if lang_code == su_country
      end
      # Search for partial match - language code and dialect
      for lang_code in languages
        country = lang_code.split('-').first
        return lang_code if country == su_country
      end
      # Default
      return @default_l10n
    end



    # Debug method that compares the availible translations against a spesified
    # prototype. Outputs the result to the Console.
    #
    # @param [String] prototype_l10n The translation to compare against.
    #
    # @return [String]
    # @since 2.5.0
    def check(prototype_l10n)
      puts "\nChecking language files for missing strings against #{prototype_l10n}..."

      prototype = self.new( @path, @default_l10n )
      prototype.load( prototype_l10n )

      temp = self.new( @path, @default_l10n )

      keys = prototype.dictionary.keys

      prototype.translations.each { |code, data|
        next if code == prototype_l10n
        temp.load(code)
        puts "\n=== #{data['name']} (#{code}) ==="
        missing = keys - temp.dictionary.keys
        puts "> Missing #{missing.length} keys:"
        missing.each { |str| p str }
      }

      self.load(org)
      "\nDone\n\n"
    end

    private

    def read_metadata(file)
      match = file.readline.match(/^(?:\xEF\xBB\xBF)?@title:\s*"(.+)"/u)
      return nil if match.nil?
      # Language data is read into a hash
      lang_data = {
        'author' => 'unknown',
        'contact' => ''
      }
      # The Name is required and MUST be the first line in the file.
      lang_data['name'] = match[1]
      # The next following lines are optional and can be in any order,
      # but with comments or skipped lines.
      2.times {
        match = file.readline.match(/@(\w+):\s*"(.+)"/u)
        if match && ['author','contact'].include?(match[1])
          lang_data[ match[1] ] = match[2]
        end
      }
      lang_data
    end

  end # class TT::Babelfish
end