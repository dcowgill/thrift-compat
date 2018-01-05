package compat_test

import (
	"bytes"
	"encoding/json"
	"log"
	"testing"

	"github.com/dcowgill/thrift-compat/gen/go/v1"
	"github.com/dcowgill/thrift-compat/gen/go/v2"
	"github.com/dcowgill/thrift-go/thrift"
)

// Adorns a test function with common setup and teardown.
func setup(fn func(t *testing.T, h helper)) func(t *testing.T) {
	return func(t *testing.T) {
		rw := new(bytes.Buffer)
		transport := thrift.NewStreamTransportRW(rw)
		protocol := thrift.NewTBinaryProtocol(transport, true, true)
		fn(t, newHelper(protocol))
	}
}

func TestAll(t *testing.T) {
	// A v2 client should be able to read a v1 enum value, even if v2 adds
	// new enum values, as long as v2 did not remove the value being read.
	t.Run("add value to enum (forward)", setup(func(t *testing.T, h helper) {
		a := v1.NewDeviceStateChanged()
		a.DeviceName = "foo"
		a.State = v1.State_off
		h.Write(t, a)
		b := v2.NewDeviceStateChanged()
		h.Read(t, b)
		if a.DeviceName != b.DeviceName {
			t.Fatalf("b.DeviceName is %q, want %q", b.DeviceName, a.DeviceName)
		}
		if int64(a.State) != int64(b.State) || a.State.String() != b.State.String() {
			t.Fatalf("b.State is %d (%q), want %d (%q)",
				b.State, b.State.String(), a.State, a.State.String())
		}
	}))

	// Unexpectedly, a v1 client will successfully read a v2 enum even if
	// the enum value only exists in v2.
	// N.B. this is not true in all language targets and therefore this
	// behavior should not be relied upon.
	t.Run("add value to enum (backward)", setup(func(t *testing.T, h helper) {
		a := v2.NewDeviceStateChanged()
		a.DeviceName = "foo"
		a.State = v2.State_standby // doesn't exist in v1
		h.Write(t, a)
		b := v1.NewDeviceStateChanged()
		h.Read(t, b)
		if a.DeviceName != b.DeviceName {
			t.Fatalf("b.DeviceName is %q, want %q", b.DeviceName, a.DeviceName)
		}
		// The correct integer value must be transmitted, even though
		// there isn't a corresponding v1 enum.
		if int64(a.State) != int64(b.State) {
			t.Fatalf("b.State is %d, want %d", b.State, a.State)
		}
	}))

	// A v2 client should be able to read a v1 DeviceEvent.
	t.Run("add member to union (forward)", setup(func(t *testing.T, h helper) {
		a := v1.NewDeviceEvent()
		a.Payload = v1.NewDeviceEventPayload()
		a.Payload.StateChanged = v1.NewDeviceStateChanged()
		a.Payload.StateChanged.DeviceName = "bar"
		a.Payload.StateChanged.State = v1.State_on
		h.Write(t, a)
		b := v2.NewDeviceEvent()
		h.Read(t, b)
		// It is safe to compare JSON representations here because
		// nothing was renamed.
		if p, q := dumps(a), dumps(b); p != q {
			t.Fatalf("JSON repr of b is %s, want %s", q, p)
		}
	}))

	// Unexpectedly, a v1 client will successfully read a v2 DeviceEvent,
	// even if the event payload uses a union field that only exists in v2.
	// N.B. this is not true in all language targets and therefore this
	// behavior should not be relied upon.
	t.Run("add member to union (backward)", setup(func(t *testing.T, h helper) {
		a := v2.NewDeviceEvent()
		a.Payload = v2.NewDeviceEventPayload()
		a.Payload.Deleted = v2.NewDeviceDeleted()
		a.Payload.Deleted.DeviceName = "baz"
		a.Payload.Deleted.Reason = "quz"
		h.Write(t, a)
		b := v1.NewDeviceEvent()
		h.Read(t, b)
		// The new union field does not exist in v1, but since it was
		// provided, we nevertheless expect it to be non-nil.
		// Also, the set-field count must be zero.
		if b.Payload == nil || b.Payload.CountSetFieldsDeviceEventPayload() != 0 {
			t.Fatal("either Payload is nil or it has non-zero set fields")
		}
	}))
}

//
// helpers
//

type readable interface {
	Read(p thrift.TProtocol) error
}

type writable interface {
	Write(p thrift.TProtocol) error
}

type helper struct{ protocol thrift.TProtocol }

func newHelper(p thrift.TProtocol) helper {
	return helper{p}
}

func (h helper) Write(t *testing.T, v writable) {
	if err := v.Write(h.protocol); err != nil {
		t.Fatalf("write error: %s", err)
	}
	if err := h.protocol.Flush(); err != nil {
		t.Fatalf("flush error: %s", err)
	}
}

func (h helper) Read(t *testing.T, v readable) {
	if err := v.Read(h.protocol); err != nil {
		t.Fatalf("read error: %s", err)
	}
}

func dumps(v interface{}) string {
	data, err := json.Marshal(v)
	if err != nil {
		log.Fatalf("dumps: %v", err)
	}
	return string(data)
}
