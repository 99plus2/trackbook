require 'trackbook/pkpass'

require 'test/unit'

class TestPKPass < Test::Unit::TestCase
  include Trackbook::PKPass

  def test_create_pkpass
    files = {
      'pass.json' => File.read(File.expand_path("../fixtures/pass.json", __FILE__))
    }
    assert create_pkpass(files)
  end

  def test_create_manifest
    files = {
      'pass.json' => File.read(File.expand_path("../fixtures/pass.json", __FILE__))
    }
    assert_equal '{"pass.json":"fafa94efef8ea0215e514deaba36cf8e65394619"}', create_manifest(files)
  end

  def test_sign_manifest
    manifest = '{"pass.json":"fafa94efef8ea0215e514deaba36cf8e65394619"}'
    assert sign_manifest(manifest)
  end

  def test_compress_files
    zip = compress_files("pass.pkpass", {
      'pass.json' => File.read(File.expand_path("../fixtures/pass.json", __FILE__))
    })
    assert zip
  end
end
