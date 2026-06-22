import 'package:firebase_messaging/firebase_messaging.dart';

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final List<RemoteMessage> notificationHistory = [];

  Future<void> initialize() async {
    await _messaging.requestPermission();
    
    FirebaseMessaging.onMessage.listen((message) {
      notificationHistory.insert(0, message);
    });
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
  
  // Expose stream so viewmodels can still rebuild UI
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
}
