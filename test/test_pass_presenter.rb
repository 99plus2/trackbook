require 'trackbook/pass_presenter'

require 'test/unit'

class TestPass < Test::Unit::TestCase
  include Trackbook::PassPresenter

  def test_format_pass
    pass = {
      'pass_type_id' => "1234567890.pass.com.example",
      'serial_number' => "1Z9999999999999999"
    }
    assert pass = format_pass(pass)

    assert_equal 1, pass['formatVersion']
    assert_equal "1234567890", pass['teamIdentifier']
    assert_equal "pass.com.example", pass['passTypeIdentifier']
    assert_equal "1Z9999999999999999", pass['serialNumber']
  end
end
