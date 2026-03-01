#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

# SPDX-FileCopyrightText: 2026 Vox Pupuli
# SPDX-License-Identifier: GPL-3.0-only

#
# openproject::health_check - Bolt task
#
# Checks the health of an OpenProject instance via the built-in health check
# endpoint at /health_checks. Supports individual component checks (database,
# mail, puma, worker) and the aggregate 'all' check.
#
# Reference: https://www.openproject.org/docs/installation-and-operations/
#            operation/monitoring/
#

require 'json'
require 'net/http'
require 'uri'

# --- helpers ----------------------------------------------------------------

def error(msg, kind, details = {})
  result = {
    '_error' => {
      'msg'     => msg,
      'kind'    => kind,
      'details' => details,
    },
  }
  $stdout.puts(result.to_json)
  exit 1
end

# --- main -------------------------------------------------------------------

params           = JSON.parse($stdin.read)
check_type       = params.fetch('check_type', 'default')
base_url         = params.fetch('base_url', 'https://localhost')
follow_redirects = params.fetch('follow_redirects', true)
insecure         = params.fetch('insecure', false)
auth_password    = params.fetch('auth_password', nil)
timeout          = params.fetch('timeout', 10)

# Build the health check URL.
path = case check_type
       when 'default'
         '/health_checks/default'
       when 'all'
         '/health_checks/all'
       else
         "/health_checks/#{check_type}"
       end

url = URI.join("#{base_url.chomp('/')}/", path.sub(%r{^/}, ''))

# Perform the HTTP request.
max_redirects = follow_redirects ? 5 : 0
redirects     = 0

begin
  loop do
    http = Net::HTTP.new(url.host, url.port)
    http.open_timeout = timeout
    http.read_timeout = timeout

    if url.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = insecure ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
    end

    request = Net::HTTP::Get.new(url.request_uri)
    request.basic_auth('health_check', auth_password) if auth_password

    response = http.request(request)

    if response.is_a?(Net::HTTPRedirection) && redirects < max_redirects
      redirects += 1
      url = URI.parse(response['location'])
      next
    end

    result = {
      'status'     => response.code.to_i,
      'body'       => response.body,
      'url'        => url.to_s,
      'check_type' => check_type,
      'success'    => response.is_a?(Net::HTTPSuccess),
    }

    $stdout.puts(result.to_json)
    exit(result['success'] ? 0 : 1)
  end
rescue StandardError => e
  error(
    "Health check request failed: #{e.message}",
    'openproject/health-check-failed',
    {
      'url'        => url.to_s,
      'check_type' => check_type,
      'exception'  => e.class.name,
    }
  )
end
