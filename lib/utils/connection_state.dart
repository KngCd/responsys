import 'dart:async';

class ServerConnectionState {
  static bool isConnected = false;
  static Timer? connectionTimer;
  static StreamController<bool> connectionStream = StreamController.broadcast();
  
  static void setConnected(bool value) {
    if (value != isConnected) {
      isConnected = value;
      connectionStream.add(value);
    }
  }
  
  static Stream<bool> get stream => connectionStream.stream;
  
  static void dispose() {
    connectionTimer?.cancel();
    connectionTimer = null;
    connectionStream.close();
  }
}