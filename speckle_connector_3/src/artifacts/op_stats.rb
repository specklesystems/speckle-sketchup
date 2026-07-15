# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../constants/path_constants'

module SpeckleConnector3
  module Artifacts
    # Collects per-phase timings + counters for a 4.0 artefact operation (send or
    # receive), for before/after comparison of pipeline optimisations. Phases are
    # cumulative (safe to call `time` with the same key in a loop). `report`
    # prints a summary to the Ruby console AND appends one JSON line to
    # `{SPECKLE_APPDATA_PATH}/<kind>_stats.jsonl` so runs can be diffed offline.
    class OpStats
      attr_writer :version_id

      # @param kind [String] 'receive' or 'send' — names the log file + console prefix
      def initialize(kind = 'receive', version_id = nil)
        @kind = kind
        @version_id = version_id
        @phases = Hash.new(0.0)
        @counts = Hash.new(0)
        @info = {}
        @t0 = Time.now.to_f
      end

      # Accumulates the block's wall time under `key` (seconds). Returns the block value.
      def time(key)
        t = Time.now.to_f
        result = yield
        @phases[key] += Time.now.to_f - t
        result
      end

      def add(key, n = 1)
        @counts[key] += n
      end

      def set(key, value)
        @info[key] = value
      end

      def report
        total = (Time.now.to_f - @t0).round(3)
        line = { at: Time.now.to_s, kind: @kind, version: @version_id, total_s: total }
          .merge(@info)
          .merge(@phases.transform_keys { |k| "#{k}_s" }.transform_values { |v| v.round(3) })
          .merge(@counts)
        puts "[#{@kind}-stats] version=#{@version_id} total=#{total}s"
        puts "  phases: #{@phases.map { |k, v| "#{k}=#{v.round(2)}s" }.join(' | ')}"
        puts "  counts: #{@counts.map { |k, v| "#{k}=#{v}" }.join(' | ')} #{@info.map { |k, v| "#{k}=#{v}" }.join(' ')}"
        append_log(line)
        line
      end

      private

      def append_log(line)
        path = File.join(SPECKLE_APPDATA_PATH, "#{@kind}_stats.jsonl")
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'a') { |f| f.puts(line.to_json) }
      rescue StandardError => e
        puts "Speckle: could not write #{@kind} stats (#{e.message})"
      end
    end
  end
end
