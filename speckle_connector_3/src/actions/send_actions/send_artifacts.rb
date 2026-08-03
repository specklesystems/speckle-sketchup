# frozen_string_literal: true

require_relative '../action'
require_relative '../../accounts/accounts'
require_relative '../../convertors/units'
require_relative '../../operations/send_artifacts'

module SpeckleConnector3
  module Actions
    # Speckle 4.0 send: extract the parquet artefact bundle from the selected
    # entities (ToSpeckleV3, single pass) and upload it via the v2 data endpoints.
    # The ingestion is created by the DUI before the send reaches Ruby (its id +
    # pre-allocated versionId arrive as arguments) — one ingestion per publish,
    # owned by the DUI. After the upload the SERVER creates the version (for
    # .dat-less bundles only once its datgen job built the viewer .dat); the DUI
    # subscribes to the ingestion (via the ingestionId in setModelSendResult) and
    # shows 'version created' + the View CTA only when the server reports success.
    # The alternative to {Actions::Send} (JSON serialize + sendBatchViaBrowser).
    class SendArtifacts < Action
      # When true, Send only EXTRACTS the parquet bundle to a local folder
      # (~/Documents/speckle-skp-test) and skips the upload — so a real .skp can
      # be validated through ToSpeckleV3 without a v2 server. Set true to debug
      # extraction locally; false does the full extract -> upload flow.
      EXTRACT_ONLY = false

      # @param state [States::State] the current state of the {App::SpeckleConnectorApp}
      # @param resolve_id [String] the JS promise id to resolve
      # @param model_card_id [String] the model card being sent
      # @param ingestion_id [String, nil] the DUI-created ingestion for this publish
      # @param version_id [String, nil] the pre-allocated version id of that ingestion
      # @return [States::State] the new updated state object
      def self.update_state(state, resolve_id, model_card_id, ingestion_id = nil, version_id = nil)
        t_start = Time.now.to_f
        state.sketchup_state.sketchup_model.active_path = nil
        units = Converters::SKETCHUP_UNITS[state.sketchup_state.length_units]
        model_card = state.speckle_state.send_cards[model_card_id]

        unless model_card.send_filter.selected_object_ids.any?
          return empty_selection_error(state, resolve_id, model_card_id)
        end

        entities = state.sketchup_state.sketchup_model.entities.select do |e|
          model_card.send_filter.selected_object_ids.any?(e.persistent_id.to_s)
        end

        if EXTRACT_ONLY
          progress(state, model_card_id, 'Extracting artefacts (local, no upload)')
          begin
            result = Operations::SendArtifacts.extract_only(entities, units, 'skp-send',
                                                            state.user_state.model_preferences)
          rescue StandardError => e
            puts "Speckle 4.0 EXTRACT-ONLY FAILED: #{e.message}\n#{e.backtrace&.first(8)&.join("\n")}"
            return send_error(state, resolve_id, model_card_id, e.message)
          end
          puts "Speckle 4.0 EXTRACT-ONLY: #{result[:count]} objects -> #{result[:dir]} (base '#{result[:base]}')"
          puts "Speckle 4.0 TOTAL time: #{(Time.now.to_f - t_start).round(2)}s"
          state = send_result(state, model_card_id, result[:base], result[:conversion_results])
          return state.with_add_queue_js_command('sendArtifacts', "sendBinding.receiveResponse('#{resolve_id}')")
        end

        if ingestion_id.to_s.empty? || version_id.to_s.empty?
          return send_error(state, resolve_id, model_card_id,
                            'No ingestion received from the DUI — the 4.0 artefact send requires a DUI/server with ingestion pre-allocation support.')
        end

        account = Accounts.get_account_by_id(model_card.account_id)
        params = {
          server_url: account['serverInfo']['url'],
          project_id: model_card.project_id,
          model_id: model_card.model_id,
          token: account['token'],
          ingestion_id: ingestion_id,
          version_id: version_id
        }

        progress(state, model_card_id, 'Extracting + uploading artefacts')
        begin
          result = Operations::SendArtifacts.upload_bundle(entities, units, params,
                                                           state.user_state.model_preferences)
        rescue StandardError => e
          puts "Speckle 4.0 artefact send FAILED: #{e.message}\n#{e.backtrace&.first(8)&.join("\n")}"
          return send_error(state, resolve_id, model_card_id, e.message)
        end
        puts "Speckle 4.0 artefact upload done — version #{version_id} (project #{model_card.project_id})"
        puts "Speckle 4.0 TOTAL time: #{(Time.now.to_f - t_start).round(2)}s"

        state = send_result(state, model_card_id, version_id, result[:conversion_results],
                            result[:ingestion_id])
        resolve_js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state.with_add_queue_js_command('sendArtifacts', resolve_js_script)
      end

      # Emits the DUI send-complete event. With an ingestionId the DUI subscribes
      # to the ingestion and shows 'version created' + the View CTA only once the
      # server reports success (the version does not exist until then — the server
      # creates it, possibly after its datgen job). Without one (EXTRACT_ONLY
      # debug path) the DUI shows the result immediately.
      def self.send_result(state, model_card_id, version_id, conversion_results = [], ingestion_id = nil)
        args = { modelCardId: model_card_id, versionId: version_id, sendConversionResults: conversion_results || [] }
        args[:ingestionId] = ingestion_id unless ingestion_id.to_s.empty?
        state.with_add_queue_js_command('setModelSendResult', "sendBinding.emit('setModelSendResult', #{args.to_json})")
      end

      def self.send_error(state, resolve_id, model_card_id, message)
        state = state.with_add_queue_js_command('resolveSend', "sendBinding.receiveResponse('#{resolve_id}')")
        args = { modelCardId: model_card_id, error: "4.0 send failed: #{message}" }
        state.with_add_queue_js_command('setModelsError', "sendBinding.emit('setModelError', #{args.to_json})")
      end

      def self.progress(state, model_card_id, message)
        args = { modelCardId: model_card_id, progress: { progress: nil, status: message } }
        state.instant_message_sender.call("sendBinding.emit('setModelProgress', #{args.to_json})")
      end

      def self.empty_selection_error(state, resolve_id, model_card_id)
        resolve_js_script = "sendBinding.receiveResponse('#{resolve_id}')"
        state = state.with_add_queue_js_command('resolveSend', resolve_js_script)
        args = { modelCardId: model_card_id, error: 'No objects were found. Please update your send filter!' }
        state.with_add_queue_js_command('setModelsError', "sendBinding.emit('setModelError', #{args.to_json})")
      end
    end
  end
end
