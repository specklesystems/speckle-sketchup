# frozen_string_literal: true

require 'tmpdir'
require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../../convertors/to_native_v3'
require_relative '../../convertors/clean_up'
require_relative '../../artifacts/artifact_downloader'
require_relative '../../artifacts/parquet_source'

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
          converter.wrap_name = LOCAL_BASE if LOCAL_ROUND_TRIP
          count = LOCAL_ROUND_TRIP ? converter.receive(local_dir, LOCAL_BASE) : download_and_build(state, model_card_id, converter)
          merge_coplanar(state, converter)
        rescue StandardError => e
          model.commit_operation
          puts "Speckle 4.0 receive FAILED: #{e.message}\n#{e.backtrace&.first(8)&.join("\n")}"
          converter.stats.report # partial phases still tell us where it died
          return receive_error(state, resolve_id, model_card_id, e.message)
        end
        model.commit_operation
        puts "Speckle 4.0 receive complete: #{count} objects in #{(Time.now.to_f - t_start).round(2)}s"
        converter.stats.set(:backend, Artifacts::ParquetSource.backend.is_a?(Module) ? 'pure-ruby' : 'duckdb')
        converter.stats.set(:merge_pref, state.user_state.model_preferences[:merge_coplanar_faces] ? true : false)
        converter.stats.report

        args = {
          modelCardId: model_card_id,
          bakedObjectIds: converter.created_top_level_ids,
          conversionResults: converter.conversion_results
        }
        state = state.with_add_queue_js_command(
          'setModelReceiveResult', "receiveBinding.emit('setModelReceiveResult', #{args.to_json})"
        )
        state.with_add_queue_js_command('receive', "receiveBinding.receiveResponse('#{resolve_id}')")
      end

      # Post-receive coplanar merge (v2 parity: {Actions::ReceiveObjects}) — undoes the
      # SGEO triangulation by removing edges between coplanar same-material faces.
      # Gated on the same model preference as v2; runs inside the receive operation.
      def self.merge_coplanar(state, converter)
        return unless state.user_state.model_preferences[:merge_coplanar_faces]

        t_merge = Time.now.to_f
        converter.stats.time(:merge_coplanar) { Converters::CleanUp.merge_coplanar_faces(converter.converted_faces) }
        puts "  [timing] merged coplanar faces (#{converter.converted_faces.length} baked) " \
             "in #{(Time.now.to_f - t_merge).round(2)}s"
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

        # The bundle's file prefix ("base") is producer-chosen — the connector uses the
        # pre-allocated versionId, file importers use the source file's stem — so derive
        # it from the listing instead of assuming versionId (ENG-8945). Only the
        # `.parquet` tables are the bundle; sidecars like `<versionId>.viewer.dat` are
        # viewer-only and skipped.
        files = files.select { |f| f[:name].end_with?('.parquet') }
        nodes = files.find { |f| f[:name].end_with?('.envelope.nodes.parquet') }
        raise "No envelope.nodes table in artefact bundle for version #{version_id}" unless nodes

        base = nodes[:name].delete_suffix('.envelope.nodes.parquet')

        dir = File.join(Dir.tmpdir, 'speckle', 'receive', version_id)
        converter.wrap_name = [model_card.project_name, model_card.model_name]
                              .reject { |n| n.to_s.empty? }.join(' - ')
        converter.receive_key = "#{model_card.project_id}/#{model_card.model_id}"
        converter.stats.version_id = version_id
        local_paths = converter.stats.time(:download) { downloader.download(files, dir) }
        converter.stats.set(:bundle_files, files.length)
        converter.stats.set(:bundle_bytes, local_paths.sum { |f| File.size(f) })
        puts "  [timing] downloaded #{files.length} artefact files -> #{dir}"
        converter.receive(dir, base)
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
