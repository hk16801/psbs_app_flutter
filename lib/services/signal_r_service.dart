import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _hubConnection;
  bool isConnected = false;
  bool reconnecting = false;
  int retryCount = 0;
  final int maxRetries = 5;
  String? hubUrl;
  String? userId;

  /// Set hub URL before starting connection
  void setHubUrl(String url) {
    hubUrl = url;
  }

  /// Start connection with userId
  Future<void> startConnection(String hubUrl, String userId) async {
    if (isConnected || reconnecting) return;

    reconnecting = true;
    this.userId = userId;

    final urlWithUserId = "$hubUrl?userId=${Uri.encodeComponent(userId)}";
    _hubConnection = HubConnectionBuilder()
        .withUrl(urlWithUserId)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.onclose(({Exception? error}) {
      print("⚠️ SignalR Disconnected: ${error?.toString()}");
      isConnected = false;
      reconnecting = false;
      _attemptReconnect();
    });

    try {
      await _hubConnection!.start();
      isConnected = _hubConnection!.state == HubConnectionState.Connected;
      reconnecting = false;
      retryCount = 0;
      print("✅ SignalR Connected.");
    } catch (error) {
      print("❌ SignalR Connection Error: $error");
      reconnecting = false;
      retryCount++;
      if (retryCount < maxRetries) {
        Future.delayed(
            Duration(seconds: 5), () => startConnection(hubUrl, userId));
      } else {
        print("Max retries reached. Giving up.");
      }
    }
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnect() {
    if (!reconnecting && retryCount < maxRetries) {
      retryCount++;
      int delay = retryCount < 3 ? 1000 : 5000;
      Future.delayed(Duration(milliseconds: delay),
          () => startConnection(hubUrl!, userId!));
    }
  }

  /// Send message to server
  Future<void> invoke(String methodName, List<Object?> args) async {
    if (!isConnected) {
      print("⚠️ SignalR not connected. Retrying...");
      await Future.doWhile(() async {
        await Future.delayed(Duration(milliseconds: 500));
        return !isConnected;
      }).timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception("SignalR connection timeout");
      });
    }

    try {
      await _hubConnection!.invoke(methodName, args: args.cast<Object>());
    } catch (error) {
      print("❌ Error invoking $methodName: $error");
      throw Exception("Error invoking $methodName: $error");
    }
  }

  /// Listen to a SignalR event
  void on(String methodName, Function(List<Object?>?) callback) {
    _hubConnection?.on(methodName, callback);
  }

  /// Stop listening to an event
  void off(String methodName) {
    _hubConnection?.off(methodName);
  }

  /// Stop the connection
  Future<void> stopConnection() async {
    await _hubConnection?.stop();
    print("🛑 SignalR Connection Stopped.");
  }
}

final SignalRService signalRService = SignalRService();
