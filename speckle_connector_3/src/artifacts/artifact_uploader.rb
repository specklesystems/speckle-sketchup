# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module SpeckleConnector3
  module Artifacts
    # Uploads an already-built artefact bundle via the Speckle v2 data endpoints —
    # a pure-Ruby mirror of the SDK `ArtifactPipeline.UploadFilesAsync`:
    # sign -> presigned PUT per file -> complete (which creates the version).
    #
    # The bundle is filename-keyed and count-agnostic: the server signs one PUT per
    # basename under versions/{versionId}/{basename}, and `complete` commits with
    # the pre-allocated versionId. The ingestion + versionId are created upstream
    # (the JS DUI3 frontend) and passed in here.
    class ArtifactUploader
      # Concurrent PUTs per file (IO-bound; presigned URLs are independent, so
      # ordering doesn't matter — mirrors ArtifactDownloader's queue).
      MAX_PARALLEL = 6

      # @return [Artifacts::OpStats, nil] optional send-stats collector
      attr_accessor :stats

      # @param server_url [String] e.g. https://app.speckle.systems
      # @param project_id [String]
      # @param ingestion_id [String] server-minted model-ingestion id
      # @param token [String] account bearer token
      def initialize(server_url, project_id, ingestion_id, token)
        @server_url = server_url.to_s.chomp('/')
        @project_id = project_id
        @ingestion_id = ingestion_id
        @token = token
      end

      # @param files [Hash{String=>String}] basename => local path
      # @param root_id [String] synthetic root id (e.g. "binary-{name}")
      # @param total_children_count [Integer]
      # @return [String, nil] the version id echoed by complete (may be nil; the
      #   caller already holds the pre-allocated id)
      def upload(files, root_id, total_children_count)
        signed = timed(:sign) { sign(files.keys) }
        uploads = signed['uploads'] || {}
        files.each_key do |name|
          raise "Server did not sign an upload for file '#{name}'" if uploads[name].nil?
        end
        etags = timed(:upload) { put_files(files, uploads) }
        timed(:complete) { complete(etags, root_id, total_children_count) }
      end

      private

      # PUTs the files concurrently; returns {name => etag}. A worker error is
      # re-raised after all threads finish.
      def put_files(files, uploads)
        queue = Queue.new
        files.each { |name, path| queue << [name, path] }
        etags = {}
        mutex = Mutex.new
        errors = Queue.new
        threads = Array.new([MAX_PARALLEL, files.length].min) do
          Thread.new do
            loop do
              name, path = begin
                queue.pop(true)
              rescue ThreadError
                break
              end
              begin
                etag = put_file(path, uploads[name])
                mutex.synchronize { etags[name] = etag }
              rescue StandardError => e
                errors << e
              end
            end
          end
        end
        threads.each(&:join)
        raise errors.pop unless errors.empty?

        etags
      end

      def timed(key, &block)
        @stats ? @stats.time(key, &block) : block.call
      end

      def endpoint(suffix)
        URI("#{@server_url}/api/v2/projects/#{@project_id}/modelingestion/#{@ingestion_id}/uploads/#{suffix}")
      end

      def sign(file_names)
        post_json(endpoint('sign'), { files: file_names })
      end

      def complete(etags, root_id, total_children_count)
        resp = post_json(endpoint('complete'), { etags: etags, rootId: root_id, totalChildrenCount: total_children_count })
        resp.is_a?(Hash) ? resp['versionId'] : nil
      end

      def post_json(uri, body)
        request(uri) do
          req = Net::HTTP::Post.new(uri)
          req['Content-Type'] = 'application/json'
          req['Authorization'] = "Bearer #{@token}"
          req.body = body.to_json
          req
        end
      end

      # Streams the file to the presigned URL (no full-file buffering) and returns
      # the ETag VERBATIM (quotes included) — the server's `complete` compares it
      # against S3's stored etag, which is quoted, so stripping quotes would cause
      # an "etag mismatch" (matches the SDK's BlobApiHelpers.ParseEtagHeader).
      def put_file(path, presigned)
        uri = URI(presigned['url'])
        file = File.open(path, 'rb')
        begin
          resp = http_for(uri).request(build_put(uri, path, presigned, file))
        ensure
          file.close
        end
        raise "PUT #{File.basename(path)} failed: #{resp.code} #{resp.body}" unless resp.is_a?(Net::HTTPSuccess)

        etag = resp['etag'] || resp['ETag']
        raise "PUT #{File.basename(path)} response had no ETag header" if etag.nil?

        etag
      end

      def build_put(uri, path, presigned, file)
        req = Net::HTTP::Put.new(uri)
        req['Content-Type'] = 'application/octet-stream'
        (presigned['additionalRequestHeaders'] || {}).each { |k, v| req[k] = v }
        req.body_stream = file
        req['Content-Length'] = File.size(path).to_s
        req
      end

      def request(uri)
        resp = http_for(uri).request(yield)
        unless resp.is_a?(Net::HTTPSuccess)
          raise "#{uri.path} failed: #{resp.code} #{resp.body}"
        end

        body = resp.body.to_s
        body.empty? ? {} : JSON.parse(body)
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
