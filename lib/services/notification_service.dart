import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Gère la demande de permission, la récupération du token FCM et
/// l'affichage des notifications reçues pendant que l'app est ouverte.
///
/// L'envoi effectif des notifications (au bon utilisateur, au bon moment)
/// est fait côté serveur par la Cloud Function déclenchée sur écriture de
/// `commandes/{id}` — voir functions/src/index.ts. Ce service ne fait que
/// réceptionner et afficher côté client.
///
/// Sur le web, `flutter_local_notifications` n'est pas disponible : les
/// notifications reçues onglet actif sont ignorées (le badge/l'écran de
/// suivi de commande suffit), et celles reçues onglet en arrière-plan (ou
/// fermé) sont affichées nativement par le navigateur via
/// web/firebase-messaging-sw.js.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const _canalId = 'statuts_commandes';
  static const _canalNom = 'Suivi des commandes';

  // Clé VAPID de votre appli web Firebase (Console → Project Settings →
  // Cloud Messaging → Web configuration → "Generate key pair"). Requise
  // uniquement pour obtenir un token FCM depuis un navigateur.
  static const _cleVapidWeb = 'REMPLACER_PAR_VOTRE_CLE_VAPID';

  Future<void> initialiser() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    if (kIsWeb) {
      // La création de canal Android et flutter_local_notifications
      // n'existent pas sur le web ; les notifications d'arrière-plan sont
      // déjà gérées par le service worker.
      return;
    }

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

  Future<String?> obtenirToken() {
    if (kIsWeb) {
      return _messaging.getToken(vapidKey: _cleVapidWeb);
    }
    return _messaging.getToken();
  }

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
