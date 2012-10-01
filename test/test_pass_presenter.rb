require 'trackbook/pass_presenter'

require 'test/unit'
require 'time'

class TestPass < Test::Unit::TestCase
  include Trackbook::PassPresenter

  DELIVERED_PASS = {
    'pass_type_id' => "1234567890.pass.com.example",
    'serial_number' => "1Z9999999999999999",
    'authentication_token' => "6ad6738983ce899bb5c33f70d9fab474",
    'description' => "Nexus 7",
    'activity' => [
      {"location" => "Chicago IL 60614", "status" => "Delivered", "timestamp" => Time.parse("2012-09-06 17:07:00 UTC")},
      {"location" => "Chicago IL", "status" => "Out for delivery", "timestamp" => Time.parse("2012-09-06 04:49:00 UTC")},
      {"location" => "Chicago IL", "status" => "Arrival scan", "timestamp" => Time.parse("2012-09-06 02:44:00 UTC")},
      {"location" => "Addison IL", "status" => "Departure scan", "timestamp" => Time.parse("2012-09-06 01:54:00 UTC")},
      {"location" => "Addison IL", "status" => "Arrival scan", "timestamp" => Time.parse("2012-09-05 23:43:00 UTC")},
      {"location" => "Chicago IL", "status" => "Departure scan", "timestamp" => Time.parse("2012-09-05 23:02:00 UTC")},
      {"location" => "Chicago IL", "status" => "Arrival scan", "timestamp" => Time.parse("2012-09-05 22:26:00 UTC")},
      {"location" => "Hodgkins IN", "status" => "Departure scan", "timestamp" => Time.parse("2012-09-05 21:49:00 UTC")},
      {"location" => "Hodgkins IN", "status" => "Arrival scan", "timestamp" => Time.parse("2012-09-05 21:23:00 UTC")},
      {"location" => "Louisville KY", "status" => "Departure scan", "timestamp" => Time.parse("2012-09-05 17:38:00 UTC")},
      {"location" => "Louisville KY", "status" => "Origin scan", "timestamp" => Time.parse("2012-09-05 13:27:00 UTC")},
      {"status" => "Billing information received", "timestamp" => Time.parse("2012-09-04 16:43:57 UTC")}
    ]
  }

  PENDING_PASS = {
    'pass_type_id' => "1234567890.pass.com.example",
    'serial_number' => "1Z9999999999999999",
    'authentication_token' => "6ad6738983ce899bb5c33f70d9fab474",
    'description' => "Paper",
    'deliver_on' => Time.parse("2012-10-03 00:00 UTC"),
    'deliver_in' => 3,
    'activity' => [
      {"status" => "Billing information received", "timestamp" => Time.parse("2012-10-01 10:20:08 UTC")}
    ]
  }

  def test_format_delivered_pass
    assert pass = format_pass(DELIVERED_PASS)

    assert_equal 1, pass['formatVersion']

    assert_equal "1234567890", pass['teamIdentifier']
    assert_equal "pass.com.example", pass['passTypeIdentifier']

    assert_equal "1Z9999999999999999", pass['serialNumber']
    assert_equal "6ad6738983ce899bb5c33f70d9fab474", pass['authenticationToken']

    assert_equal "Trackbook", pass['organizationName']
    assert_equal "UPS Tracking information for Nexus 7", pass['description']
    assert_nil pass['relevantDate']

    assert_equal "Nexus 7", pass['generic']['primaryFields'][0]['value']
    assert_equal "Delivered", pass['generic']['secondaryFields'][0]['value']
    assert_equal "1Z9999999999999999", pass['generic']['auxiliaryFields'][0]['value']

    assert_equal <<-EOS.chomp, pass['generic']['backFields'][0]['value']
09/06  Chicago IL 60614  Delivered
09/06  Chicago IL  Out for delivery
09/06  Chicago IL  Arrival scan
09/06  Addison IL  Departure scan
09/05  Addison IL  Arrival scan
09/05  Chicago IL  Departure scan
09/05  Chicago IL  Arrival scan
09/05  Hodgkins IN  Departure scan
09/05  Hodgkins IN  Arrival scan
09/05  Louisville KY  Departure scan
09/05  Louisville KY  Origin scan
09/04    Billing information received
EOS
  end

  def test_format_pending_pass
    assert pass = format_pass(PENDING_PASS)

    assert_equal 1, pass['formatVersion']

    assert_equal "1234567890", pass['teamIdentifier']
    assert_equal "pass.com.example", pass['passTypeIdentifier']

    assert_equal "1Z9999999999999999", pass['serialNumber']
    assert_equal "6ad6738983ce899bb5c33f70d9fab474", pass['authenticationToken']

    assert_equal "Trackbook", pass['organizationName']
    assert_equal "UPS Tracking information for Paper", pass['description']
    assert_equal "2012-10-03T00:00:00Z", pass['relevantDate']

    assert_equal "3", pass['generic']['headerFields'][0]['value']
    assert_equal "Paper", pass['generic']['primaryFields'][0]['value']
    assert_equal "Billing information received", pass['generic']['secondaryFields'][0]['value']
    assert_equal "1Z9999999999999999", pass['generic']['auxiliaryFields'][0]['value']
    assert_equal "Oct  3", pass['generic']['auxiliaryFields'][1]['value']

    assert_equal <<-EOS.chomp, pass['generic']['backFields'][0]['value']
10/01    Billing information received
EOS
  end

  def test_present_delivered_pkpass
    assert pkpass = present_pkpass(DELIVERED_PASS)
    File.open(File.expand_path("../passes/delivered.pkpass", __FILE__), 'w') do |f|
      f.write pkpass
    end
  end

  def test_present_pending_pkpass
    assert pkpass = present_pkpass(PENDING_PASS)
    File.open(File.expand_path("../passes/pending.pkpass", __FILE__), 'w') do |f|
      f.write pkpass
    end
  end
end
