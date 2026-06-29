# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module SpeckleConnector3
  module Artifacts
    # Minimal GraphQL client for the server's **client-side model ingestion** API
    # (server >= 3.0.3) — mirrors the SDK `ModelIngestionResource`. The connector
    # creates a `clientSide` ingestion (which comes back already in `processing`
    # state with a **pre-allocated versionId**), uploads the artefact bundle under
    # that versionId, and the v2 `/uploads/complete` REST call creates the version.
    class ModelIngestionClient
      def initialize(server_url, token)
        @server_url = server_url.to_s.chomp('/')
        @token = token
      end

      # Creates a client-side ingestion session.
      # @return [Hash] { id: <ingestionId>, version_id: <pre-allocated versionId> }
      def create(project_id, model_id, source_app_slug, source_app_version, progress_message: 'Sending from SketchUp')
        query = <<~GRAPHQL
          mutation IngestionCreate($input: ModelIngestionCreateInput!) {
            projectMutations {
              modelIngestionMutations {
                create(input: $input) {
                  id
                  versionId
                  statusData { ... on HasModelIngestionStatus { status } }
                }
              }
            }
          }
        GRAPHQL

        input = {
          projectId: project_id,
          modelId: model_id,
          sourceData: {
            sourceApplicationSlug: source_app_slug,
            sourceApplicationVersion: source_app_version
          },
          progressMessage: progress_message
        }

        data = post_graphql(query, { input: input })
        created = data.dig('projectMutations', 'modelIngestionMutations', 'create')
        raise 'Model ingestion create returned no data' if created.nil?

        { id: created['id'], version_id: created['versionId'] }
      end

      private

      def post_graphql(query, variables)
        uri = URI("#{@server_url}/graphql")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 120

        req = Net::HTTP::Post.new(uri)
        req['Content-Type'] = 'application/json'
        req['Authorization'] = "Bearer #{@token}"
        req.body = { query: query, variables: variables }.to_json

        resp = http.request(req)
        raise "GraphQL HTTP #{resp.code}: #{resp.body}" unless resp.is_a?(Net::HTTPSuccess)

        json = JSON.parse(resp.body.to_s)
        if json['errors']
          raise "GraphQL errors: #{json['errors'].map { |e| e['message'] }.join('; ')}"
        end

        json['data'] || raise('GraphQL response contained no data')
      end
    end
  end
end
