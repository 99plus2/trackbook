require 'time'
require 'ups_shipping'

module Trackbook
  module Track
    extend self

    def track_shipment(number)
      result = {}
      ups = Shipping::UPS.new(ENV['UPS_EMAIL'], ENV['UPS_PASS'], ENV['UPS_KEY'])
      resp = ups.track_shipment(number)['TrackResponse']

      return result if resp['Response']['ResponseStatusDescription'] != 'Success'

      if date = resp['Shipment']['ScheduledDeliveryDate']
        result['deliver_on'] = Time.parse(date + " 00:00 UTC")
        result['deliver_in'] = ((result['deliver_on'] - Time.now.utc) / (60 * 60 * 24)).ceil
      end

      activities = resp['Shipment']['Package']['Activity']
      activities = [activities] unless activities.is_a?(Array)

      result['activity'] = []
      activities.each do |activity|
        address = activity['ActivityLocation']['Address']
        location = [address['City'], address['StateProvinceCode'], address['PostalCode']].compact.join(" ")
        location = nil if location == ""
        result['activity'] << {
          'location' => location,
          'status' => activity['Status']['StatusType']['Description'],
          'timestamp' => Time.parse("#{activity['Date']} #{activity['Time']} UTC")
        }
      end

      result
    end
  end
end
