# Blanchisserie — Application de collecte/livraison

Application Flutter (Android en priorité) pour digitaliser la collecte et
la livraison de linge d'un point de blanchisserie desservant un immeuble
résidentiel et son quartier à Ouagadougou. Une seule base de code, trois
vues selon le rôle : **client**, **collecteur**, **gérant**.

- Front : Flutter (Dart), état géré avec Riverpod.
- Backend : Firebase (Auth téléphone/OTP, Cloud Firestore, Cloud
  Messaging, Storage), pas de serveur custom.
- Notifications : une Cloud Function (`functions/`) envoie un push FCM au
  client à chaque changement de statut important de sa commande.
- Interface entièrement en français, persistance offline Firestore
  activée (les actions faites sans réseau se synchronisent seules).

## Obtenir l'APK sans être développeur·se

Chaque envoi de code sur ce dépôt déclenche automatiquement
(`.github/workflows/build-apk.yml`) une construction de l'application sur
les serveurs GitHub, qui publie le fichier `.apk` prêt à installer dans
l'onglet **Releases** du dépôt GitHub :

`https://github.com/lardiamarcel-hub/Blanchisserie/releases`

Ouvrez ce lien sur le téléphone Android, téléchargez `app-release.apk` de
la version la plus récente, ouvrez le fichier téléchargé pour l'installer
(Android demandera d'autoriser « Installer des applications inconnues »
la première fois — c'est normal, il ne s'agit pas du Play Store).

**Tant que le projet Firebase réel n'est pas connecté, cet APK fonctionne
en mode démonstration** : tous les écrans s'affichent, mais la connexion
par téléphone/SMS ne peut pas encore fonctionner (elle a besoin d'un
projet Firebase, qui doit obligatoirement être créé avec le compte Google
du propriétaire de l'activité, personne d'autre ne peut le faire à sa
place). Une fois ce projet créé et ses informations transmises, un
nouveau build automatique produit l'APK définitif, pleinement
fonctionnel, sans rien réinstaller de plus.

## Arborescence

```
lib/
  main.dart                 Point d'entrée, init Firebase/notifications
  app.dart                  MaterialApp (thème, locale FR)
  firebase_options.dart     Généré par `flutterfire configure` (gabarit ici)
  core/
    constants/               Enums métier (rôles, statuts, types de service...)
    theme/                    Thème (gros boutons, texte lisible)
    router/auth_gate.dart     Aiguillage selon connexion + rôle + profil
    utils/formatters.dart     Formatage prix/dates en français
  models/                    UserModel, CommandeModel, TarifModel
  services/                  AuthService, FirestoreService, NotificationService
  providers/                 Providers Riverpod (auth, commandes, tarifs)
  screens/
    auth/                     Téléphone, OTP, complétion de profil
    client/                   Accueil, création commande, suivi, historique
    collecteur/               Collectes du jour, livraisons
    gerant/                   Indicateurs, commandes, tarifs, collecteurs
  widgets/                    Composants réutilisés (carte commande, badge statut)
functions/                  Cloud Function TypeScript (notifications FCM)
firestore.rules             Règles de sécurité Firestore
firestore.indexes.json      Index composites nécessaires aux requêtes
firebase.json               Config déploiement (rules, indexes, functions)
android/                    Projet Android (Gradle, manifeste, icônes placeholder)
web/                        Cible Flutter Web (index.html, manifest, service worker FCM)
```

## Modèle de données Firestore

- `users/{uid}` : `telephone, role (client|collecteur|gerant), nom, adresse?,
  etage?, appartement?, tokenNotification?, dateCreation`
- `commandes/{id}` : `clientId, collecteurId?, statut, typeService,
  creneauSouhaite, poidsEstimeKg?, poidsReelKg?, prixEstime?, prixFinal?,
  modePaiement?, paye, note?, etoiles?, historiqueStatuts[], dateCreation`
  (+ `clientNom/clientTelephone/clientAdresse` dénormalisés pour l'affichage
  côté collecteur/gérant sans requête supplémentaire)
- `tarifs/{typeService}` : `typeService, prixParKg, description`
- `comptesPreinscrits/{telephone}` : pré-inscription d'un collecteur créé
  par le gérant, consommée automatiquement à la première connexion OTP de
  la personne (voir `FirestoreService.resoudreProfilApresConnexion`)

Machine à états d'une commande :
`demandeCreee → collectePlanifiee → collecteEffectuee → enTraitement → pret
→ enLivraison → livree` (annulation possible avant `collecteEffectuee`).

## Mise en route

### 1. Prérequis

- Flutter SDK (stable récent) installé et fonctionnel (`flutter doctor`).
- Un projet Firebase (créé sur https://console.firebase.google.com).
- Node.js 20+ si vous comptez déployer les Cloud Functions.

### 2. Récupérer les dépendances

```bash
flutter pub get
```

### 3. Connecter le projet Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android,web
```

Cette commande régénère `lib/firebase_options.dart` avec les vraies clés
de votre projet (Android **et** web), et télécharge automatiquement
`android/app/google-services.json` (ce fichier n'est pas versionné, voir
`.gitignore` — c'est normal, chaque développeur/environnement doit
récupérer le sien).

Pour la version web, complétez en plus **manuellement**
`web/firebase-messaging-sw.js` avec les mêmes valeurs que le bloc `web`
généré dans `firebase_options.dart` (ce fichier tourne hors de Dart, il
ne peut pas les lire), et renseignez la clé VAPID dans
`lib/services/notification_service.dart` (`_cleVapidWeb`), récupérable
dans Console Firebase → Paramètres du projet → Cloud Messaging → Web
Push certificates.

### 4. Activer les services Firebase nécessaires

Dans la console Firebase :

- **Authentication** → activer le fournisseur **Téléphone**. Ajoutez un
  numéro de test si vous développez sans SMS réels.
- **Firestore Database** → créer la base (mode production).
- **Cloud Messaging** → aucune action spécifique, juste vérifier qu'il est
  activé (c'est le cas par défaut).
- **Storage** → activer si vous comptez ajouter des photos du linge plus tard.

### 5. Déployer les règles, index et Cloud Functions

```bash
npm --prefix functions install
firebase deploy --only firestore:rules,firestore:indexes,functions
```

### 6. Créer le tout premier compte gérant

Le gérant crée normalement les comptes collecteurs depuis l'app (écran
"Collecteurs"), mais **le tout premier compte gérant doit être créé
manuellement** puisque personne n'existe encore pour le pré-inscrire :

1. Connectez-vous une première fois dans l'app avec le numéro de
   téléphone du gérant (un profil `client` est créé automatiquement).
2. Dans la console Firebase → Firestore → collection `users` → ouvrez le
   document correspondant à cet utilisateur, et changez le champ `role`
   de `client` à `gerant`.
3. Redémarrez l'app : l'écran gérant apparaît.

### 7. Lancer / générer l'APK

```bash
flutter run              # test sur un appareil/émulateur
flutter build apk --release
```

> Note Android : ce dépôt contient un projet `android/` fonctionnel
> (Gradle, manifeste, icônes) mais pas les fichiers binaires générés par
> Flutter lui-même (`gradlew`, `gradle-wrapper.jar`) — Flutter les
> régénère automatiquement au premier `flutter run`/`flutter build` s'ils
> sont absents. Les icônes de lancement fournies sont des aplats de
> couleur temporaires : remplacez-les (ex: avec le package
> `flutter_launcher_icons`) avant publication.

### 8. Lancer / déployer la version web

```bash
flutter run -d chrome                 # test en local
flutter build web --release           # génère build/web/ (statique)
```

`build/web/` est un site statique déployable tel quel sur n'importe quel
hébergeur (Firebase Hosting, Netlify, Vercel, un simple serveur nginx...).
Avec Firebase Hosting déjà configuré pour ce projet :

```bash
firebase deploy --only hosting
```

(ajoutez d'abord un bloc `"hosting"` dans `firebase.json` pointant sur
`build/web` si ce n'est pas déjà fait — `firebase init hosting` s'en charge).

**Différences web à connaître :**

- La connexion par téléphone/OTP fonctionne, mais Firebase affiche un
  léger défi reCAPTCHA invisible (normal, propre au web) avant l'envoi du
  SMS.
- Les notifications reçues **onglet actif** ne s'affichent pas en toast
  (le package `flutter_local_notifications` ne supporte pas le web) ;
  celles reçues **onglet en arrière-plan ou fermé** s'affichent nativement
  grâce à `web/firebase-messaging-sw.js`. Le suivi de commande dans
  l'app reste à jour en temps réel dans tous les cas (Firestore).
- Sur certains navigateurs (Safari notamment), les notifications push web
  ont des limitations connues côté navigateur, indépendantes de l'app.

## À propos des versions de dépendances

Les packages Firebase/`intl` dans `pubspec.yaml` sont fixés à des versions
qui fonctionnent ensemble au moment de la rédaction. Si `flutter pub get`
signale un conflit de versions (fréquent avec `intl`, dont la version est
liée à celle de `flutter_localizations` embarquée dans votre SDK Flutter),
suivez simplement la version que `flutter pub get` recommande dans son
message d'erreur, ou lancez `flutter pub upgrade --major-versions` pour
tout aligner sur les dernières versions compatibles.

## Hors périmètre V1 (volontairement non développé)

- Intégration API mobile money (paiement juste déclaré par le collecteur).
- Géolocalisation GPS / calcul d'itinéraire.
- Abonnements/forfaits mensuels.
- Avis publics ou classement des collecteurs.
- Build iOS (l'architecture Flutter le permet sans réécriture, mais n'a
  pas été générée dans cette session).

## Sécurité

Les règles Firestore (`firestore.rules`) couvrent le cas d'usage MVP :
chaque client ne voit que ses commandes, les collecteurs voient/mettent à
jour les commandes en cours, le gérant a un accès complet, et la
collection `comptesPreinscrits` n'est lisible que par le gérant ou par le
numéro de téléphone concerné. À revoir/durcir avant une mise en
production à plus grande échelle (ex: limiter précisément les champs
qu'un collecteur peut modifier sur une commande).
