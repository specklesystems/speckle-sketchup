# frozen_string_literal: true

module SpeckleConnector3
  module Auth
    # SketchUp's side of a browser sign-in: the system browser and the main-thread timers the attempt polls from.
    module SketchupHost
      # Opens the authorization page in the user's default browser.
      module Browser
        def self.open(url)
          UI.openURL(url)
        end
      end

      # Repeating UI timers; their blocks run on SketchUp's main thread between UI events.
      module Timers
        def self.start_timer(interval_seconds, &tick)
          UI.start_timer(interval_seconds, true, &tick)
        end

        def self.stop_timer(timer_id)
          UI.stop_timer(timer_id)
        end
      end
    end
  end
end
