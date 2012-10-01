require 'json'
require 'redis'
require 'securerandom'

if url = ENV['REDISTOGO_URL']
  uri = URI.parse(url)
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
else
  $redis = Redis.new
end

module Trackbook
  module Pass
    extend self

    MONTH_SECS = 30 * 24 * 60 * 60
    WEEK_SECS = 7 * 24 * 60 * 60

    def split_team_and_pass_type_id(id)
      id.split(".", 2)
    end

    def generate_pass(pass_type_id, tracking_number, description = nil)
      team_id, pass_type_id = split_team_and_pass_type_id(pass_type_id)

      pass = {
        'pass_type_id' => "#{team_id}.#{pass_type_id}",
        'serial_number' => tracking_number,
        'authentication_token' => SecureRandom.hex(16),
      }
      pass['description'] = description if description

      key = "passes:#{pass_type_id}:#{tracking_number}"
      $redis.set key, pass.to_json
      $redis.expire key, MONTH_SECS

      [pass_type_id, tracking_number]
    end

    def find_pass(pass_type_id, serial_number)
      if pass = $redis.get("passes:#{pass_type_id}:#{serial_number}")
        JSON.parse(pass)
      end
    end

    def find_authenticated_pass(pass_type_id, serial_number, authentication_token)
      if pass = find_pass(pass_type_id, serial_number)
        if pass['authentication_token'] == authentication_token
          pass
        end
      end
    end

    def register_pass(pass_type_id, serial_number, device_id, push_token = nil)
      registration = {
        'device_id' => device_id,
        'pass_type_id' => pass_type_id,
        'serial_number' => serial_number,
        'push_token' => push_token
      }

      key = "registrations:#{pass_type_id}:#{serial_number}:#{device_id}"
      res = $redis.setnx key, registration.to_json
      $redis.expire key, WEEK_SECS

      key = "devices:#{pass_type_id}:#{device_id}"
      $redis.sadd key, serial_number
      $redis.expire key, WEEK_SECS

      res
    end

    def unregister_pass(pass_type_id, serial_number, device_id)
      res = $redis.del("registrations:#{pass_type_id}:#{serial_number}:#{device_id}")

      key = "devices:#{pass_type_id}:#{device_id}"
      $redis.srem key, serial_number
      $redis.expire key, WEEK_SECS

      res > 0
    end

    def find_device_registered_serial_numbers(pass_type_id, device_id)
      $redis.smembers("devices:#{pass_type_id}:#{device_id}")
    end
  end
end
