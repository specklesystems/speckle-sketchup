#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------
module SpeckleConnector
  module TT

    # Loads the appropriate C Extension loader after ensuring the appropriate
    # version has been copied from the staging area.
    #
    # @since 2.9.0
    class CExtensionManager

      class IncompatibleVersion < RuntimeError; end

      VERSION_PATTERN = /\d+\.\d+\.\d+$/

      # The `path` argument should point to the path where a 'stage' folder is
      # located with the following folder structure:
      #
      #   + `path`
      #   +-+ stage
      #     +-+ 1.8
      #     | +-+ HelloWorld.so
      #     |   + HelloWorld.bundle
      #     +-+ 2.0
      #       +-+ HelloWorld.so
      #         + HelloWorld.bundle
      #
      # The appropriate file will be copied on demand to a folder structure like:
      # `path`/<EXTENSION_VERSION>/<RUBY_VERSION>/HelloWorld.so
      #
      # When a new version is deployed the files will be copied again from the
      # staging area to a new folder named with the new extension version.
      #
      # The old versions are cleaned up if possible. This attempt is done upon
      # each time #prepare_path is called.
      #
      # This way the C extensions can be updated because they are never loaded
      # from the staging folder directly.
      #
      # @param [String] path The location where the C Extensions are located.
      # @since 2.9.0
      def initialize( path, version )
        # ENV, __FILE__, $LOAD_PATH, $LOADED_FEATURE and more might return an
        # encoding different from UTF-8. It's often ASCII-US or ASCII-8BIT.
        # If the developer has derived from these strings the encoding sticks with
        # it and will often lead to errors further down the road when trying to
        # load the files. To work around this the path is attempted to be
        # relabeled as UTF-8 if we can produce a valid UTF-8 string.
        # I'm forcing an encoding instead of converting because the encoding label
        # of the strings seem to be consistently mislabeled - the data is in
        # fact UTF-8.
        if path.respond_to?(:encoding)
          test_path = path.dup.force_encoding("UTF-8")
          path = test_path if test_path.valid_encoding?
        end

        unless version =~ VERSION_PATTERN
          raise ArgumentError, 'Version must be in "X.Y.Z" format'
        end
        unless File.directory?( path )
          raise IOError, "Stage path not found: #{path}"
        end

        @version = version
        @path = path
        @stage = File.join( path, 'stage' )
        @target = File.join( path, version )

        @log = []

        # See method comments for more info.
        #require_file_utils()
      end

      # Copies the necessary C Extension libraries to a version dependent folder
      # from where they can be loaded. This will allow the SketchUp RBZ installer
      # to update the extension without running into errors when trying to
      # overwrite files from previous installation.
      #
      # @return [String] The path where the extensions are located.
      # @since 2.9.0
      def prepare_path
        log("prepare_path")

        pointer_size = ['a'].pack('P').size * 8 # 32 or 64
        ruby = RUBY_VERSION.split('.')[0..1].join('.') # Get Major.Minor string.
        platform = ( TT::System::PLATFORM_IS_OSX ) ? 'osx' : 'win'
        platform = "#{platform}#{pointer_size}"
        stage_path = File.join( @stage, ruby, platform )
        target_path = File.join( @target, ruby, platform )
        fallback = false

        log("> stage_path: #{stage_path}")
        log("> target_path: #{target_path}")

        begin
          # Copy files if target doesn't exist.
          unless File.directory?(stage_path)
            raise IncompatibleVersion, "Staging directory not found: #{stage_path}"
          end
          unless File.directory?( target_path )
            log("MKDIR: #{target_path}")
            require_file_utils() # See method comments for more info.
            log(FileUtils.mkdir_p( target_path ))
          end
          stage_content = Dir.entries( stage_path )
          target_content = Dir.entries( target_path )
          log("> stage_content: #{stage_content}")
          log("> target_content: #{target_content}")
          unless (stage_content - target_content).empty?
            log("COPY: #{stage_path} => #{target_path}")
            require_file_utils() # See method comments for more info.
            log(FileUtils.copy_entry( stage_path, target_path ))
          end

          # Clean up old versions.
          version_pattern = /\d+\.\d+\.\d+$/
          filter = File.join( @path, '*' )
          log("> cleanup: #{filter}")
          Dir.glob( filter ).each { |entry|
            log(">>>   entry: #{entry}")
            next unless File.directory?( entry )
            log(">>> @target: #{@target} (#{entry.downcase == @target.downcase})")
            log(">>>  @stage: #{@stage} (#{entry.downcase == @stage.downcase})")
            log(">>>>> @target vs entry")
            log(">>>>> #{entry.class.name}: #{entry.bytes}") if entry.respond_to?(:bytes)
            log(">>>>> #{@target.class.name}: #{@target.bytes}") if @target.respond_to?(:bytes)
            next if entry.downcase == @stage.downcase || entry.downcase == @target.downcase
            log(">>>   match: #{entry =~ version_pattern}")
            next unless entry =~ version_pattern
            begin
              log("REMOVE: #{entry}")
              require_file_utils # See method comments for more info.
              log(FileUtils.rm_r( entry ))
            rescue
              log_warn("#{TT::Lib::PLUGIN_NAME} - Unable to clean up: #{entry}")
            end
          }
        rescue Errno::EACCES
          if fallback
            UI.messagebox(
              "Failed to load #{TT::Lib::PLUGIN_NAME}. Missing permissions to " <<
                "Plugins and temp folder."
            )
            raise
          else
            # Even though the temp folder contains the username, it appear to be
            # returned in DOS 8.3 format which Ruby 1.8 can open. Fall back to
            # using the temp folder for these kind of systems.
            log_warn("#{TT::Lib::PLUGIN_NAME} - Unable to access: #{target_path}")
            temp_tt_lib_path = File.join( temp_path, TT::Lib::PLUGIN_ID )
            target_path = File.join( temp_tt_lib_path, @version, ruby, platform )
            log_warn("#{TT::Lib::PLUGIN_NAME} - Falling back to: #{target_path}")
            fallback = true
            retry
          end
        end

        target_path
      end

      # @return [String]
      # @since 2.9.0
      def to_s
        object_hex_id = "0x%x" % (self.object_id << 1)
        "<##{self.class}::#{object_hex_id}>"
      end
      alias :inspect :to_s

      # @since 2.10.7
      def print_log
        puts @log.join("\n")
      end

      private

      # @since 2.10.7
      def log(value)
        string = value.is_a?(String) ? value : value.inspect
        @log << string
        string
      end

      # @since 2.10.7
      def log_warn(value)
        puts log(value)
      end

      # Return the system temp path from the environment variables.
      #
      # @since 2.10.7
      def temp_path
        File.expand_path( ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] )
      end

      # Attempt to load the Standard Library FileUtils module. Fall back to
      # bundled 1.8 copy.
      #
      # @since 2.9.0
      def require_file_utils
        if RUBY_VERSION.to_i == 1
          path = File.dirname( __FILE__ ) # rubocop:disable SketchupSuggestions/FileEncoding
          require File.join( path, 'thirdparty', 'fileutils.rb' )
        else
          begin
            require 'fileutils'
          rescue LoadError
            # A bug in SketchUp 2014 M0 caused the drive letter for the Ruby
            # Standard Library to be incorrect if SketchUp was started by
            # clicking a SKP file on a drive (network drive?) different from
            # where SketchUp was installed.
            #
            # This cause the fileutils to fail to load. To work around this the
            # file is required right before it is needed. That should make the
            # file needed only the first time after installing a new version.
            # Makes the code awkward and ugly, but alas. :(
            std_lib_path = Sketchup.find_support_file( 'Tools/RubyStdLib' ) # rubocop:disable SketchupSuggestions/SketchupFindSupportFile
            unless $LOAD_PATH.include?( std_lib_path )
              UI.messagebox(
                'Due to a bug in SketchUp 2014 M0 the standard library was ' <<
                  'not loaded. Please start SketchUp from a link on the drive ' <<
                  'it was installed to instead of from clicking an SKP on a ' <<
                  'different drive.'
              ) unless @load_error_displayed
              @load_error_displayed = true
            end
            puts $LOAD_PATH.join("\n")
            raise
          end
        end # if RUBY_VERSION
      end

    end # class

  end # module
end

