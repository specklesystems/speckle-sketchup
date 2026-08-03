# frozen_string_literal: true

module SpeckleConnector3
  # The Speckle host-app slug of this connector — the single source of truth for
  # everything that reports the app identity (bundle `meta.produced_by`, the DUI
  # `getSourceAppName` response, ingestion source app).
  HOST_APP_SLUG = 'sketchup'
end
