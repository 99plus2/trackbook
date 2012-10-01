require 'trackbook/pass'

require 'test/unit'
require 'redis'

class TestPass < Test::Unit::TestCase
  include Trackbook::Pass

  def setup
    @redis = Redis.new
  end

  def test_generate_pass
    pass_type_id, serial_number = generate_pass(@redis, "1234567890.pass.com.example")
    assert_equal "pass.com.example", pass_type_id
    assert_match %r{^........-....-....-....-............$}, serial_number
  end

  def test_find_pass
    pass_type_id, serial_number = generate_pass(@redis, "1234567890.pass.com.example")
    assert pass = find_pass(@redis, pass_type_id, serial_number)

    assert_equal "1234567890.pass.com.example", pass['pass_type_id']
    assert_equal serial_number, pass['serial_number']
    assert pass['authentication_token']
  end

  def test_format_pass
    pass_type_id, serial_number = generate_pass(@redis, "1234567890.pass.com.example")
    assert pass = find_pass(@redis, pass_type_id, serial_number)
    assert pass = format_pass(pass)

    assert_equal 1, pass['formatVersion']
    assert_equal "1234567890", pass['teamIdentifier']
    assert_equal "pass.com.example", pass['passTypeIdentifier']
    assert_equal serial_number, pass['serialNumber']
  end
end
