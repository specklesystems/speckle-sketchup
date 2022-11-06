# frozen_string_literal: true

require 'JSON'
require 'json'
require 'sketchup'
require 'speckle_connector/converter/converter_sketchup'
require 'speckle_connector/accounts'

module SpeckleSystems
  module SpeckleConnector
    UNITS = { 0 => 'in', 1 => 'ft', 2 => 'mm', 3 => 'cm', 4 => 'm', 5 => 'yd' }.freeze
    public_constant :UNITS
    @to_send = {}
    @connected = false

    def self.queue_send(stream_id, converted)
      @to_send = { stream_id: stream_id, converted: converted }
      send_from_queue(stream_id) if @connected
    end

    def self.send_from_queue(stream_id)
      return unless @to_send[:stream_id] == stream_id

      @dialog.execute_script("convertedFromSketchup('#{@to_send[:stream_id]}',#{@to_send[:converted].to_json})")
      @dialog.execute_script("oneClickSend('#{@to_send[:stream_id]}')")
      @to_send = {}
    end

    # rubocop:disable SketchupSuggestions/Compatibility
    def self.init_dialog
      options = {
        dialog_title: 'SpeckleSketchUp',
        preferences_key: 'example.htmldialog.materialinspector',
        style: UI::HtmlDialog::STYLE_DIALOG,
        min_width: 250,
        min_height: 50
      }
      dialog = UI::HtmlDialog.new(options)
      dialog.center
      dialog
    end
    # rubocop:enable SketchupSuggestions/Compatibility

    def self.create_dialog(show: true)
      if @dialog&.visible?
        @dialog.bring_to_front
      else
        @dialog ||= init_dialog
        @dialog.add_action_callback('send_selection') do |_action_context, stream_id|
          send_selection(stream_id)
          nil
        end
        @dialog.add_action_callback('receive_objects') do |_action_context, base, stream_id|
          receive_objects(base, stream_id)
          nil
        end
        @dialog.add_action_callback('reload_accounts') do |_action_context|
          reload_accounts
        end
        @dialog.add_action_callback('init_local_accounts') do |_action_context|
          init_local_accounts
        end
        @dialog.add_action_callback('load_saved_streams') do |_action_context|
          load_saved_streams
        end
        @dialog.add_action_callback('save_stream') do |_action_context, stream_id|
          save_stream(stream_id)
        end
        @dialog.add_action_callback('remove_stream') do |_action_context, stream_id|
          remove_stream(stream_id)
        end
        @dialog.add_action_callback('notify_connected') do |_action_context, stream_id|
          notify_connected(stream_id)
        end

        # set connected to false when dialog is closed
        @dialog.set_can_close do
          @connected = false
          !@connected
        end

        if DEV_MODE
          puts('Launching Speckle Connector from http://localhost:8081')
          @dialog.set_url('http://localhost:8081')
        else
          html_file = File.join(File.dirname(File.expand_path(__FILE__)), 'html', 'index.html')
          puts("Launching Speckle Connector from #{html_file}")
          @dialog.set_file(html_file)
        end

        @dialog.show if show
      end
      @dialog
    end

    def self.notify_connected(stream_id)
      @connected = true
      send_from_queue(stream_id)
    end

    def self.convert_to_speckle(to_convert)
      converter = ConverterSketchup.new(UNITS[Sketchup.active_model.options['UnitsOptions']['LengthUnit']])
      to_convert.map { |entity| converter.convert_to_speckle(entity) }
    end

    def self.send_selection(stream_id)
      converted = convert_to_speckle(Sketchup.active_model.selection)
      puts("converted #{converted.count} objects for stream #{stream_id}")
      # puts(converted.to_json)
      @dialog.execute_script("convertedFromSketchup('#{stream_id}',#{converted.to_json})")
    rescue StandardError => e
      puts(e)
      @dialog.execute_script("sketchupOperationFailed('#{stream_id}')")
    end

    def self.receive_objects(base, stream_id)
      puts("received objects from stream #{stream_id}")
      model = Sketchup.active_model
      converter = ConverterSketchup.new(UNITS[model.options['UnitsOptions']['LengthUnit']])
      converter.traverse_commit_object(base)
      @dialog.execute_script("finishedReceiveInSketchup('#{stream_id}')")
    rescue StandardError => e
      puts(e)
      @dialog.execute_script("sketchupOperationFailed('#{stream_id}')")
    end

    def self.one_click_send
      acct = Accounts.default_account
      return puts('No local account found. Please refer to speckle.guide for more information.') if acct.nil?

      create_dialog
      to_convert = if Sketchup.active_model.selection.count > 0
                     Sketchup.active_model.selection
                   else
                     Sketchup.active_model.entities
                   end
      if first_saved_stream.nil?
        create_stream(to_convert)
      else
        queue_send(first_saved_stream, convert_to_speckle(to_convert))
      end
    rescue StandardError => e
      puts(e)
      @dialog.execute_script("sketchupOperationFailed('#{@to_send[:stream_id]}')")
    end

    def self.first_saved_stream
      saved_streams = Sketchup.active_model.attribute_dictionary('speckle', true)['streams'] or []
      saved_streams.nil? || saved_streams.empty? ? nil : saved_streams[0]
    end

    def self.load_saved_streams
      saved_streams = Sketchup.active_model.attribute_dictionary('speckle', true)['streams'] or []
      @dialog.execute_script("setSavedStreams(#{saved_streams})")
    end

    def self.init_local_accounts
      puts('Initialisation of Speckle accounts requested by plugin')
      @dialog.execute_script("loadAccounts(#{Accounts.load_accounts.to_json})")
    end

    def self.reload_accounts
      puts('Reload of Speckle accounts requested by plugin')
      @dialog.execute_script("loadAccounts(#{Accounts.load_accounts.to_json})")
      load_saved_streams
    end

    def self.save_stream(stream_id)
      speckle_dict = Sketchup.active_model.attribute_dictionary('speckle', true)
      saved = speckle_dict['streams'] || []
      saved = saved.empty? ? [stream_id] : saved.unshift(stream_id)
      speckle_dict['streams'] = saved

      load_saved_streams
    end

    def self.remove_stream(stream_id)
      speckle_dict = Sketchup.active_model.attribute_dictionary('speckle', true)
      saved = speckle_dict['streams'] || []
      saved -= [stream_id]
      speckle_dict['streams'] = saved

      load_saved_streams
    end

    def self.create_stream(to_convert)
      acct = Accounts.default_account
      return if acct.nil?

      path = Sketchup.active_model.path
      stream_name = path ? File.basename(path, '.*') : 'Untitled SketchUp Model'
      query = 'mutation streamCreate($stream: StreamCreateInput!) {streamCreate(stream: $stream)}'
      vars = { stream: { name: stream_name, description: 'Stream created from SketchUp' } }

      # rubocop:disable SketchupSuggestions/Compatibility
      request = Sketchup::Http::Request.new("#{acct['serverInfo']['url']}/graphql", Sketchup::Http::POST)
      # rubocop:enable SketchupSuggestions/Compatibility
      request.headers = { 'Authorization' => "Bearer #{acct['token']}", 'Content-Type' => 'application/json' }
      request.body = { query: query, variables: vars }.to_json

      request.start do |_req, res|
        res_data = JSON.parse(res.body)['data']
        raise(StandardError) unless res_data

        stream_id = res_data['streamCreate']
        save_stream(stream_id)
        queue_send(stream_id, convert_to_speckle(to_convert))
        # send_selection(stream_id)
      end
      load_saved_streams
    rescue StandardError => e
      puts(e)
      puts('Could not create a new stream')
    end
  end
end
