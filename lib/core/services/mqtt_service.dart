// Platform-specific MQTT service implementation
// Uses conditional exports to select the right implementation

export 'mqtt_service_interface.dart';
export 'mqtt_service_web.dart' if (dart.library.io) 'mqtt_service_native.dart';
