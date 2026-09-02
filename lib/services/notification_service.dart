import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Gère la demande de permission, la récupération du token FCM et
/// l'affichage des notifications reçues pendant que l'app est ouverte.
///
/// L'envoi effectif des notifications (au bon utilisateur, au bon moment)
/// est fait côté serveur par la Cloud Function déclenchée sur écriture de
/// `commandes/{id}` — voir functions/src/index.ts. Ce service ne fait que
/// réceptionner et afficher côté client.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const _canalId = 'statuts_commandes';
  static const _canalNom = 'Suivi des commandes';

  Future<void> initialiser() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(const InitializationSettings(android: initAndroid));

    const canal = AndroidNotificationChannel(
      _canalId,
      _canalNom,
      description: 'Notifications de changement de statut de vos commandes',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);

    FirebaseMessaging.onMessage.listen(_afficherNotificationLocale);
  }

  Future<String?> obtenirToken() => _messaging.getToken();

  Stream<String> get surRenouvellementToken => _messaging.onTokenRefresh;

  void _afficherNotificationLocale(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNom,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
