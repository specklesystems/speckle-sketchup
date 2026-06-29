# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../convertors/to_speckle_v3'
require_relative '../artifacts/artifact_uploader'
require_relative '../artifacts/model_ingestion_client'

module SpeckleConnector3
  module Operations
    # Orchestrates a Speckle 4.0 artefact send end-to-end (Ruby-side, no JS):
    # create a client-side model ingestion (pre-allocates the versionId) -> extract
    # the parquet bundle from the selected entities (ToSpeckleV3, single pass to disk)
    # -> upload it via the v2 data endpoints. Mirrors speckle-oda's RevitModelExtractor
    # finalize tail (Complete -> glob {versionId}.*.parquet -> UploadFilesAsync).
    module SendArtifacts
      module_function

      # @param entities [Array<Sketchup::Entity>] the selected top-level entities
      # @param units [String] speckle model units
      # @param params [Hash] { server_url:, project_id:, model_id:, token:,
      #   source_app_slug:, source_app_version: }
      # @return [String] the committed version id
      def send_bundle(entities, units, params)
        t0 = Time.now.to_f
        client = Artifacts::ModelIngestionClient.new(params.fetch(:server_url), params.fetch(:token))
        ingestion = client.create(
          params.fetch(:project_id), params.fetch(:model_id),
          params.fetch(:source_app_slug), params.fetch(:source_app_version)
        )
        ingestion_id = ingestion[:id]
        version_id = ingestion[:version_id]
        if version_id.nil? || version_id.to_s.empty?
          raise 'Server did not pre-allocate a versionId on ingestion create (needs the v2 data endpoints).'
        end
        t1 = Time.now.to_f
        puts "  [timing] ingestion create: #{(t1 - t0).round(2)}s (ingestion #{ingestion_id}, version #{version_id})"

        output_dir = File.join(Dir.tmpdir, 'speckle', 'artifacts', version_id)
        FileUtils.mkdir_p(output_dir)

        extractor = Converters::ToSpeckleV3.new(units, output_dir, version_id)
        extractor.extract(entities)
        t2 = Time.now.to_f
        puts "  [timing] extract: #{(t2 - t1).round(2)}s (#{extractor.object_count} objects)"

        bundle = bundle_files(output_dir, version_id)
        uploader = Artifacts::ArtifactUploader.new(
          params.fetch(:server_url), params.fetch(:project_id), ingestion_id, params.fetch(:token)
        )
        uploader.upload(bundle, "binary-#{version_id}", extractor.object_count)
        t3 = Time.now.to_f
        puts "  [timing] upload + finalize: #{(t3 - t2).round(2)}s (#{bundle.size} files)"
        version_id
      end

      # Extract-only (no server): runs the single-pass extractor and writes the
      # parquet bundle to a stable local folder for inspection. Used to validate a
      # real .skp through ToSpeckleV3 without needing the v2 data endpoints.
      # @return [Hash] { dir:, base:, count: }
      def extract_only(entities, units, base_name)
        output_dir = File.join(Dir.home, 'Documents', 'speckle-skp-test')
        FileUtils.mkdir_p(output_dir)
        Dir.glob(File.join(output_dir, "#{base_name}.*.parquet")).each { |f| File.delete(f) }

        t0 = Time.now.to_f
        extractor = Converters::ToSpeckleV3.new(units, output_dir, base_name)
        extractor.extract(entities)
        puts "  [timing] extract: #{(Time.now.to_f - t0).round(2)}s (#{extractor.object_count} objects)"
        { dir: output_dir, base: base_name, count: extractor.object_count }
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
