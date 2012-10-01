require 'ups_shipping'

module Trackbook
  module Track
    extend self

    def track_shipment(number)
      ups = Shipping::UPS.new(ENV['UPS_EMAIL'], ENV['UPS_PASS'], ENV['UPS_KEY'])
      resp = ups.track_shipment(number)['TrackResponse']

      if resp['ResponseStatusCode'] != '1'
        return []
      end

      activities = resp['Shipment']['Package']['Activity']
      activities.inject([]) do |results, activity|
        address = activity['ActivityLocation']['Address']
        results << {
          'location' => [address['City'], address['StateProvinceCode'], address['PostalCode']].compact.join(" "),
          'status' => activity['Status']['StatusType']['Description'],
          'timestamp' => Time.parse("#{activity['Date']} #{activity['Time']}")
        }
        results
      end
    end
  end
end
