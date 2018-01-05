namespace rb v2

// State of a device.
enum State {
  standby = 3, // ADDED
  on = 1,
  off = 2
}

// A new device was created.
struct DeviceCreated {
  1: string device_name;
}

// The state of a device was changed.
struct DeviceStateChanged {
  1: string device_name;
  2: State state;
}

// An existing device was removed.
struct DeviceDeleted {
  1: string device_name;
  2: string reason;
}

// Tagged union of all possible device events.
union DeviceEventPayload {
  1: DeviceCreated created;
  2: DeviceStateChanged state_changed;
  3: DeviceDeleted deleted; // ADDED
}

// Something happened to a device.
struct DeviceEvent {
  1: DeviceEventPayload payload;
}
