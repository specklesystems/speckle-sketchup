# frozen_string_literal: true

require 'tmpdir'
require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../../convertors/to_native_v3'
require_relative '../../artifacts/artifact_downloader'

module SpeckleConnector3
  module Actions
    # Speckle 4.0 receive: rebuilds native SketchUp entities from a parquet artefact
    # bundle (ToNativeV3). The alternative to {Actions::Receive} (the JSON
    # receiveViaBrowser + ToNativeV2 path).
    #
    # LOCAL_ROUND_TRIP=true reads the bundle the Send button's extract-only mode
    # wrote to ~/Documents/speckle-skp-test (base 'skp-send') — a no-server round
    # trip. false downloads the selected version's bundle from the v2 data endpoints.
    class ReceiveArtifacts < Action
      LOCAL_ROUND_TRIP = false
      LOCAL_BASE = 'skp-send'

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id)
        model = state.sketchup_state.sketchup_model
        converter = Converters::ToNativeV3.new(model)

        model.start_operation('Receive Speckle 4.0 Artefacts', true)
        t_start = Time.now.to_f
        begin
          count = LOCAL_ROUND_TRIP ? converter.receive(local_dir, LOCAL_BASE) : download_and_build(state, model_card_id, converter)
        rescue StandardError => e
          model.commit_operation
          puts "Speckle 4.0 receive FAILED: #{e.message}\n#{e.backtrace&.first(8)&.join("\n")}"
          return receive_error(state, resolve_id, model_card_id, e.message)
        end
        model.commit_operation
        puts "Speckle 4.0 receive complete: #{count} objects in #{(Time.now.to_f - t_start).round(2)}s"

        args = {
          modelCardId: model_card_id,
          bakedObjectIds: converter.created_top_level_ids,
          conversionResults: []
        }
        state = state.with_add_queue_js_command(
          'setModelReceiveResult', "receiveBinding.emit('setModelReceiveResult', #{args.to_json})"
        )
        state.with_add_queue_js_command('receive', "receiveBinding.receiveResponse('#{resolve_id}')")
      end

      # Downloads the selected version's bundle and builds it. @return [Integer] object count
      def self.download_and_build(state, model_card_id, converter)
        model_card = state.speckle_state.receive_cards[model_card_id]
        account = Accounts.get_account_by_id(model_card.account_id)
        version_id = model_card.selected_version_id

        downloader = Artifacts::ArtifactDownloader.new(account['serverInfo']['url'], account['token'])
        files = downloader.list(model_card.project_id, model_card.model_id, version_id)
        if files.empty?
          raise "No artefact files for version #{version_id} (is it a 4.0 / schemaVersion 3 version?)"
        end

        dir = File.join(Dir.tmpdir, 'speckle', 'receive', version_id)
        downloader.download(files, dir)
        puts "  [timing] downloaded #{files.length} artefact files -> #{dir}"
        converter.receive(dir, version_id)
      end

      def self.local_dir
        File.join(Dir.home, 'Documents', 'speckle-skp-test')
      end

      def self.receive_error(state, resolve_id, model_card_id, message)
        args = { modelCardId: model_card_id, error: "4.0 receive failed: #{message}" }
        state = state.with_add_queue_js_command(
          'setModelsError', "receiveBinding.emit('setModelError', #{args.to_json})"
        )
        state.with_add_queue_js_command('receive', "receiveBinding.receiveResponse('#{resolve_id}')")
      end
    end
  end
end
