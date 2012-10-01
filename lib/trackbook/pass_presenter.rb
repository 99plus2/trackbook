require 'trackbook/pass'
require 'trackbook/pkpass'

module Trackbook
  module PassPresenter
    extend self

    def read_image_data(filename)
      path = File.join(File.expand_path("../public/images", __FILE__), filename)
      File.read(path)
    end

    def present_pkpass(pass, service_url = nil)
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
      team_id, pass_type_id = Pass.split_team_and_pass_type_id(pass['pass_type_id'])

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

        'generic' => present_fields(pass)
      }
    end

    def present_fields(pass)
      fields = {
        'auxiliaryFields' => [
          { 'key' => "number", 'label' => "NUMBER", 'value' => pass['serial_number'] },
          { 'key' => "delivered", 'label' => "Delivered by", 'value' => Time.now.strftime("%b %e %k:%M") }
        ]
      }

      if description = pass['description']
        fields['primaryFields'] = [
          { 'key' => "description", 'value' => description }
        ]
      end

      if pass['activity'] && (activity = pass['activity'].first)
        fields['secondaryFields'] = [
          { 'key' => "status", 'label' => "STATUS", 'value' => activity['status'] }
        ]
      end

      if activities = pass['activity']
        text = activities.map { |activity|
          [
           activity['timestamp'].strftime("%m/%d"),
           activity['location'],
           activity['status']
          ].join("  ")
        }.join("\n")

        fields['backFields'] = [
          { 'key' => "activity", 'label' => "ACTIVITY", 'value' => text }
        ]
      end

      fields
    end
  end
end
