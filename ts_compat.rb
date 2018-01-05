require 'test/unit'
require_relative 'rb/lib/thrift' # TODO: require 'thrift'

require_relative 'gen/rb/v1_types'
require_relative 'gen/rb/v2_types'

class TestCompat < Test::Unit::TestCase

  def setup
    transport = Thrift::MemoryBufferTransport.new()
    @protocol = Thrift::BinaryProtocol.new(transport)
  end

  # A v2 client should be able to read a v1 enum value, even if v2 adds new enum
  # values, as long as v2 did not remove the value being read.
  def test_add_value_to_enum_forward_ok
    a = V1::DeviceStateChanged.new()
    a.device_name = "foo"
    a.state = V1::State::Off
    a.write(@protocol)
    b = V2::DeviceStateChanged.new()
    b.read(@protocol)
    assert_equal(a.device_name, b.device_name)
    assert_equal(a.state, b.state)
    assert_equal(a.state.to_s, b.state.to_s)
  end

  # A v1 client should fail to read a v2 enum value that only exists in v2.
  def test_add_value_to_enum_backward_fails
    a = V2::DeviceStateChanged.new()
    a.device_name = "foo"
    a.state = V2::State::Standby
    a.write(@protocol)
    b = V1::DeviceStateChanged.new()
    assert_raise(Thrift::ProtocolException) { b.read(@protocol) }
  end

  # A v2 client should be able to read a v1 DeviceEvent.
  def test_add_field_to_union_forward_ok
    a = V1::DeviceEvent.new()
    a.payload = V1::DeviceEventPayload.new()
    a.payload.state_changed = lambda {
      e = V1::DeviceStateChanged.new()
      e.device_name = "bar"
      e.state = V1::State::On
      return e
    }.call
    a.write(@protocol)
    b = V2::DeviceEvent.new()
    b.read(@protocol)
    assert_equal(a.payload.state_changed.device_name, b.payload.state_changed.device_name)
    assert_equal(a.payload.state_changed.state, b.payload.state_changed.state)
    assert_equal(b.payload.get_set_field, :state_changed)
  end

  # A v1 client should be able to read a v2 DeviceEvent, as long as the event
  # payload uses a union field that exists in both versions.
  def test_add_field_to_union_backward_ok
    a = V2::DeviceEvent.new()
    a.payload = V2::DeviceEventPayload.new()
    a.payload.state_changed = lambda {
      e = V2::DeviceStateChanged.new()
      e.device_name = "bar"
      e.state = V1::State::On
      return e
    }.call
    a.write(@protocol)
    b = V1::DeviceEvent.new()
    b.read(@protocol)
    assert_equal(a.payload.state_changed.device_name, b.payload.state_changed.device_name)
    assert_equal(a.payload.state_changed.state, b.payload.state_changed.state)
    assert_equal(b.payload.get_set_field, :state_changed)
  end

  # A v1 client should fail to read a v2 DeviceEvent if the event payload uses a
  # union field that only exists in v2.
  def test_use_new_field_in_union_backward_fail
    a = V2::DeviceEvent.new()
    a.payload = V2::DeviceEventPayload.new()
    a.payload.deleted = lambda {
      e = V2::DeviceDeleted.new()
      e.device_name = "foo"
      e.reason = "because"
      return e
    }.call
    a.write(@protocol)
    b = V1::DeviceEvent.new()
    assert_raise(StandardError) { b.read(@protocol) }
  end

end
