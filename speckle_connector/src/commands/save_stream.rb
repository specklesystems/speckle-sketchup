# frozen_string_literal: true

require_relative 'command'
require_relative '../accounts/accounts'
require_relative '../convertors/units'
require_relative '../convertors/converter_sketchup'

module SpeckleConnector
  module Commands
    # Command to saved stream.
    class SaveStream < Command
      def _run(data)
        stream_id = data['stream_id']
        speckle_dict = Sketchup.active_model.attribute_dictionary('speckle', true)
        saved = speckle_dict['streams'] || []
        saved = saved.empty? ? [stream_id] : saved.unshift(stream_id)
        speckle_dict['streams'] = saved
        Commands::LoadSavedStreams.new(app, 'reloadAccounts')._run(data)
      end
    end
  end
end
