# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

module SpeckleConnector3
  module Artifacts
    # Downloads a version's 4.0 artefact bundle via the v2 data endpoints:
    # `GET /api/v2/projects/{p}/models/{m}/versions/{v}/artifacts` -> { files:
    # [{ name, url, expiresAt }] } (presigned S3/MinIO GETs, bare basenames), then
    # fetches each parquet file. Inverse of {ArtifactUploader}.
    class ArtifactDownloader
      def initialize(server_url, token)
        @server_url = server_url.to_s.chomp('/')
        @token = token
      end

      # @return [Array<Hash>] [{ name:, url: }, ...] for the version's bundle
      def list(project_id, model_id, version_id)
        uri = URI("#{@server_url}/api/v2/projects/#{project_id}/models/#{model_id}/versions/#{version_id}/artifacts")
        req = Net::HTTP::Get.new(uri)
        req['Authorization'] = "Bearer #{@token}"
        resp = http_for(uri).request(req)
        raise "artefacts list failed: #{resp.code} #{resp.body}" unless resp.is_a?(Net::HTTPSuccess)

        (JSON.parse(resp.body.to_s)['files'] || []).map { |f| { name: f['name'], url: f['url'] } }
      end

      # Downloads each listed file into `dest_dir`. @return [Array<String>] local paths
      def download(files, dest_dir)
        FileUtils.mkdir_p(dest_dir)
        files.map do |f|
          path = File.join(dest_dir, f[:name])
          download_to(f[:url], path)
          path
        end
      end

      private

      # Streams the presigned GET straight to disk (no full-file buffering).
      def download_to(url, path)
        uri = URI(url)
        http_for(uri).request(Net::HTTP::Get.new(uri)) do |resp|
          raise "download #{File.basename(path)} failed: #{resp.code}" unless resp.is_a?(Net::HTTPSuccess)

          File.open(path, 'wb') { |file| resp.read_body { |chunk| file.write(chunk) } }
        end
      end

      def http_for(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 600
        http
      end
    end
  end
end
