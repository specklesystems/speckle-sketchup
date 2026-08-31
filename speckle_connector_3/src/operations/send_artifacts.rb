# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../convertors/to_speckle_v3'
require_relative '../artifacts/artifact_uploader'
require_relative '../artifacts/op_stats'

module SpeckleConnector3
  module Operations
    # Speckle 4.0 artefact send, Ruby-side half: extract the parquet bundle from
    # the selected entities (ToSpeckleV3, single pass to disk) and upload it via
    # the v2 data endpoints (sign -> PUT -> complete). The ingestion is created by
    # the DUI (which also holds the pre-allocated versionId) BEFORE the send
    # reaches Ruby — one ingestion per publish, owned by the DUI. Ruby never talks
    # to the ingestion GraphQL API; `complete` here only signals "upload done" —
    # the SERVER creates the version (after its datgen job for .dat-less bundles),
    # and the DUI detects that via the ingestion status subscription.
    module SendArtifacts
      module_function

      # @param entities [Array<Sketchup::Entity>] the selected top-level entities
      # @param units [String] speckle model units
      # @param params [Hash] { server_url:, project_id:, model_id:, token:,
      #   ingestion_id:, version_id: } — ingestion_id/version_id come from the
      #   DUI-created ingestion
      # @param preferences [Hash, nil] model preferences (attribute-send settings)
      # @return [Hash] { version_id:, ingestion_id:, conversion_results: } — the
      #   pre-allocated version id (the version itself may not exist yet; the DUI
      #   tracks the ingestion until the server creates it), the ingestion id, and
      #   one DUI report row per top-level object
      def upload_bundle(entities, units, params, preferences = nil)
        stats = Artifacts::OpStats.new('send')
        ingestion_id = params.fetch(:ingestion_id)
        version_id = params.fetch(:version_id)
        stats.version_id = version_id
        t1 = Time.now.to_f

        output_dir = File.join(Dir.tmpdir, 'speckle', 'artifacts', version_id)
        FileUtils.mkdir_p(output_dir)

        extractor = Converters::ToSpeckleV3.new(units, output_dir, version_id, preferences, stats)
        extractor.extract(entities)
        t2 = Time.now.to_f
        puts "  [timing] extract: #{(t2 - t1).round(2)}s (#{extractor.object_count} objects)"

        bundle = bundle_files(output_dir, version_id)
        stats.set(:bundle_files, bundle.size)
        stats.set(:bundle_bytes, bundle.each_value.sum { |path| File.size(path) })
        uploader = Artifacts::ArtifactUploader.new(
          params.fetch(:server_url), params.fetch(:project_id), ingestion_id, params.fetch(:token)
        )
        uploader.stats = stats
        uploader.upload(bundle, "binary-#{version_id}", extractor.object_count)
        t3 = Time.now.to_f
        puts "  [timing] upload + finalize: #{(t3 - t2).round(2)}s (#{bundle.size} files)"
        stats.report
        {
          version_id: version_id,
          ingestion_id: ingestion_id,
          conversion_results: extractor.conversion_results
        }
      end

      # Extract-only (no server): runs the single-pass extractor and writes the
      # parquet bundle to a stable local folder for inspection. Used to validate a
      # real .skp through ToSpeckleV3 without needing the v2 data endpoints.
      # @return [Hash] { dir:, base:, count: }
      def extract_only(entities, units, base_name, preferences = nil)
        output_dir = File.join(Dir.home, 'Documents', 'speckle-skp-test')
        FileUtils.mkdir_p(output_dir)
        Dir.glob(File.join(output_dir, "#{base_name}.*.parquet")).each { |f| File.delete(f) }

        t0 = Time.now.to_f
        stats = Artifacts::OpStats.new('send', base_name)
        extractor = Converters::ToSpeckleV3.new(units, output_dir, base_name, preferences, stats)
        extractor.extract(entities)
        puts "  [timing] extract: #{(Time.now.to_f - t0).round(2)}s (#{extractor.object_count} objects)"
        stats.report
        { dir: output_dir, base: base_name, count: extractor.object_count,
          conversion_results: extractor.conversion_results }
      end

      # Collects every parquet file in the bundle, keyed by basename (the server
      # signs/keys per basename; .sql/other files are never produced here).
      def bundle_files(output_dir, version_id)
        Dir.glob(File.join(output_dir, "#{version_id}.*.parquet")).each_with_object({}) do |path, acc|
          acc[File.basename(path)] = path
        end
      end
    end
  end
end
