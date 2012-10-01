require 'json'
require 'securerandom'

require 'trackbook/pkpass'

module Trackbook
  module Pass
    extend self

    MONTH_SECS = 30 * 24 * 60 * 60
    WEEK_SECS  = 7 * 24 * 60 * 60

    def split_team_and_pass_type_id(id)
      id.split(".", 2)
    end

    def generate_pass(redis, pass_type_id, tracking_number)
      team_id, pass_type_id = split_team_and_pass_type_id(pass_type_id)

      pass = {
        'pass_type_id' => "#{team_id}.#{pass_type_id}",
        'serial_number' => tracking_number,
        'authentication_token' => SecureRandom.hex(16),
      }

      key = "passes:#{pass_type_id}:#{tracking_number}"
      redis.set key, pass.to_json
      redis.expire key, MONTH_SECS

      [pass_type_id, tracking_number]
    end

    def read_image_data(filename)
      path = File.join(File.expand_path("../public/images", __FILE__), filename)
      File.read(path)
    end

    def build_pass_pkpass(pass, service_url = nil)
      pass = format_pass(pass)
      pass['webServiceURL'] = service_url if service_url

      files = {
        "pass.json"   => pass.to_json,
        "icon.png"    => read_image_data("icon.png"),
        "icon@2x.png" => read_image_data("icon@2x.png"),
        "logo.png"    => read_image_data("logo.png"),
        "logo@2x.png" => read_image_data("logo@2x.png")
      }

      PKPass.create_pkpass(files)
    end

    def format_pass(pass)
      team_id, pass_type_id = split_team_and_pass_type_id(pass['pass_type_id'])

      {
        'formatVersion' => 1,

        'teamIdentifier' => team_id,
        'passTypeIdentifier' => pass_type_id,

        'serialNumber' => pass['serial_number'],
        'authenticationToken' => pass['authentication_token'],

        'organizationName' => "UPS",
        'description' => "Tracking information",

        'logoText' => "UPS",
        'foregroundColor' => "rgb(255, 255, 255)",
        'backgroundColor' => "rgb(68, 0, 0)",

        'generic' => pass_fields(pass)
      }
    end

    def pass_fields(pass)
      {
        'primaryFields' => [
          { 'key' => "description", 'value' => "iPhone 5" }
        ],
        'secondaryFields' => [
          { 'key' => "status", 'label' => "STATUS", 'value' => "Out for Delivery" }
        ],
        'auxiliaryFields' => [
          { 'key' => "number", 'label' => "NUMBER", 'value' => pass['serial_number'] },
          { 'key' => "delivered", 'label' => "Delivered by", 'value' => "Today" }
        ],
        'backFields' => [
        ]
      }
    end

    def find_pass(redis, pass_type_id, serial_number)
      if pass = redis.get("passes:#{pass_type_id}:#{serial_number}")
        JSON.parse(pass)
      end
    end

    def find_authenticated_pass(redis, pass_type_id, serial_number, authentication_token)
      if pass = find_pass(redis, pass_type_id, serial_number)
        if pass['authentication_token'] == authentication_token
          pass
        end
      end
    end

    def register_pass(redis, pass_type_id, serial_number, device_id, push_token = nil)
      registration = {
        'device_id' => device_id,
        'pass_type_id' => pass_type_id,
        'serial_number' => serial_number,
        'push_token' => push_token
      }
      key = "registrations:#{serial_number}:#{device_id}"
      res = redis.setnx key, registration.to_json
      redis.expire key, WEEK_SECS
      res
    end

    def unregister_pass(redis, pass_type_id, serial_number, device_id)
      redis.del("registrations:#{serial_number}:#{device_id}") > 0
    end
  end
end
