# frozen_string_literal: true

# rubocop:disable Style/Documentation
module SpeckleConnector3
  host_os = RbConfig::CONFIG['host_os']
  OS_WIN = :windows
  OS_MAC = :macos
  OPERATING_SYSTEM = case host_os
                     when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                       OS_WIN
                     when /darwin|mac os/
                       OS_MAC
                     else
                       raise "Unsupported OS: #{host_os.inspect}"
                     end
  RUBY_VERSION_NUMBER = RUBY_VERSION.split('.')[0..1].join.to_i
end
# rubocop:enable Style/Documentation
