require 'active_support/time'
require 'time'
require 'ups_shipping'
require 'zip_to_timezone'

module Trackbook
  module Track
    extend self

    def track_shipment(number)
      result = {}
      ups = Shipping::UPS.new(ENV['UPS_EMAIL'], ENV['UPS_PASS'], ENV['UPS_KEY'])
      resp = ups.track_shipment(number)['TrackResponse']

      return result if resp['Response']['ResponseStatusDescription'] != 'Success'

      zip_code = resp['Shipment']['ShipTo']['Address']['PostalCode'] rescue nil
      zone = zone_for_zipcode(zip_code)

      if date = resp['Shipment']['ScheduledDeliveryDate']
        result['deliver_on'] = zone.parse(date)
        result['deliver_in'] = ((result['deliver_on'] - zone.now) / 1.day).ceil
      end

      activities = resp['Shipment']['Package']['Activity']
      activities = [activities] unless activities.is_a?(Array)

      result['activity'] = []
      activities.each do |activity|
        address = activity['ActivityLocation']['Address']

        location = []
        location << address['City'].capitalize if address['City']
        location << address['StateProvinceCode'] if address['StateProvinceCode']
        location << address['PostalCode'] if address['PostalCode']

        zip_code = address['PostalCode'] rescue nil
        zone = zone_for_zipcode(zip_code)

        result['activity'] << {
          'location' => location.any? ? location.join(" ") : nil,
          'status' => activity['Status']['StatusType']['Description'].to_s.capitalize,
          'timestamp' => zone.parse("#{activity['Date']} #{activity['Time']}")
        }
      end

      result
    end

    def zone_for_zipcode(zip_code)
      if zip_code
        ActiveSupport::TimeZone[ZipToTimezone.get_timezone_for(zip_code)]
      else
        ActiveSupport::TimeZone['UTC']
      end
    end
  end
end
