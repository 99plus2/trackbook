require 'trackbook/pass'

require 'test/unit'
require 'redis'

class TestPass < Test::Unit::TestCase
  include Trackbook::Pass

  def setup
    @redis = Redis.new
    @device_id = "4d5bbdc31a7b2fc19049cc0a20f4234c"
  end

  def test_generate_pass
    pass_type_id, serial_number = generate_pass(@redis, "1234567890.pass.com.example", "1Z9999999999999999")
    assert_equal "pass.com.example", pass_type_id
    assert_equal "1Z9999999999999999", serial_number
  end

  def test_find_pass
    pass_type_id, serial_number = generate_pass(@redis, "1234567890.pass.com.example", "1Z9999999999999999")
    assert pass = find_pass(@redis, pass_type_id, serial_number)

    assert_equal "1234567890.pass.com.example", pass['pass_type_id']
    assert_equal serial_number, pass['serial_number']
    assert pass['authentication_token']
  end

  def test_format_pass
    pass_type_id, serial_number = generate_pass(@redis, "1234567890.pass.com.example", "1Z9999999999999999")
    assert pass = find_pass(@redis, pass_type_id, serial_number)
    assert pass = format_pass(pass)

    assert_equal 1, pass['formatVersion']
    assert_equal "1234567890", pass['teamIdentifier']
    assert_equal "pass.com.example", pass['passTypeIdentifier']
    assert_equal serial_number, pass['serialNumber']
  end

  def test_register_pass
    pass_type_id, serial_number = generate_pass(@redis, "1234567890.pass.com.example", "1Z9999999999999999")

    unregister_pass(@redis, pass_type_id, serial_number, @device_id)
    assert register_pass(@redis, pass_type_id, serial_number, @device_id)
    assert !register_pass(@redis, pass_type_id, serial_number, @device_id)
  end

  def test_unregister_pass
    pass_type_id, serial_number = generate_pass(@redis, "1234567890.pass.com.example", "1Z9999999999999999")

    register_pass(@redis, pass_type_id, serial_number, @device_id)
    assert unregister_pass(@redis, pass_type_id, serial_number, @device_id)
    assert !unregister_pass(@redis, pass_type_id, serial_number, @device_id)
  end

  def test_registered_serial_numbers
    generate_pass(@redis, "1234567890.pass.com.example", "1Z9999999999999999")
    generate_pass(@redis, "1234567890.pass.com.example", "1Z9999999999999998")

    register_pass(@redis, "pass.com.example", "1Z9999999999999999", @device_id)
    register_pass(@redis, "pass.com.example", "1Z9999999999999998", @device_id)

    assert_equal ["1Z9999999999999998", "1Z9999999999999999"],
      find_device_registered_serial_numbers(@redis, "pass.com.example", @device_id).sort
  end
end
