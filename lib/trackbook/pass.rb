require 'json'
require 'securerandom'
require 'uuid'

require 'trackbook/pkpass'

$uuid = UUID.new

module Trackbook
  module Pass
    extend self

    def split_team_and_pass_type_id(id)
      id.split(".", 2)
    end

    def generate_pass(redis, pass_type_id)
      team_id, pass_type_id = split_team_and_pass_type_id(pass_type_id)

      serial_number = $uuid.generate

      pass = {
        'pass_type_id' => "#{team_id}.#{pass_type_id}",
        'serial_number' => serial_number,
        'authentication_token' => SecureRandom.hex(16),
      }

      redis.set "passes:#{pass_type_id}:#{serial_number}", pass.to_json

      [pass_type_id, serial_number]
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
          { 'key' => "number", 'label' => "NUMBER", 'value' => "1Z7F382V0203242533" },
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
      redis.setnx("registrations:#{serial_number}:#{device_id}", registration.to_json) == 1
    end

    def unregister_pass(redis, serial_number, device_id)
      redis.del("registrations:#{serial_number}:#{device_id}") > 0
    end
  end
end
