import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/commande_model.dart';
import '../models/tarif_model.dart';
import '../models/user_model.dart';

/// Point d'accès unique à Cloud Firestore.
///
/// La persistance offline est activée une fois pour toutes dans
/// [activerPersistanceHorsLigne], appelée au démarrage de l'app : toute
/// écriture effectuée sans réseau est mise en file d'attente localement par
/// le SDK Firestore et synchronisée automatiquement au retour de la
/// connexion, sans code supplémentaire ici.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static void activerPersistanceHorsLigne() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  // ---------------------------------------------------------------------
  // Utilisateurs
  // ---------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);

  /// Comptes créés à l'avance par le gérant (collecteur/gérant) avant la
  /// première connexion de la personne concernée, indexés par numéro de
  /// téléphone puisque l'UID Firebase Auth n'existe pas encore.
  CollectionReference<Map<String, dynamic>> get _comptesPreinscrits =>
      _db.collection('comptesPreinscrits');

  Stream<UserModel?> streamUtilisateur(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromMap(doc.id, doc.data()!) : null,
        );
  }

  /// À appeler juste après une connexion réussie : relie le compte
  /// Firebase Auth à son profil Firestore, en récupérant un éventuel
  /// pré-enregistrement fait par le gérant (cas collecteur), ou en créant
  /// un profil client vierge par défaut.
  Future<UserModel> resoudreProfilApresConnexion({
    required String uid,
    required String telephone,
  }) async {
    final docExistant = await _users.doc(uid).get();
    if (docExistant.exists) {
      return UserModel.fromMap(docExistant.id, docExistant.data()!);
    }

    final preinscrit = await _comptesPreinscrits.doc(telephone).get();
    if (preinscrit.exists) {
      final data = preinscrit.data()!;
      final nouvelUtilisateur = UserModel(
        uid: uid,
        telephone: telephone,
        role: RoleUtilisateurX.depuisTexte(data['role'] as String?),
        nom: data['nom'] as String? ?? '',
        dateCreation: DateTime.now(),
      );
      final batch = _db.batch();
      batch.set(_users.doc(uid), nouvelUtilisateur.toMap());
      batch.delete(preinscrit.reference);
      await batch.commit();
      return nouvelUtilisateur;
    }

    final nouveauClient = UserModel(
      uid: uid,
      telephone: telephone,
      role: RoleUtilisateur.client,
      nom: '',
      dateCreation: DateTime.now(),
    );
    await _users.doc(uid).set(nouveauClient.toMap());
    return nouveauClient;
  }

  Future<void> mettreAJourProfil(UserModel utilisateur) {
    return _users.doc(utilisateur.uid).set(utilisateur.toMap(), SetOptions(merge: true));
  }

  Future<void> enregistrerTokenNotification(String uid, String token) {
    return _users.doc(uid).set({'tokenNotification': token}, SetOptions(merge: true));
  }

  /// Le gérant pré-crée un compte collecteur ; le mot de passe n'existe
  /// pas, la personne se connecte simplement avec son numéro + OTP SMS.
  Future<void> creerCompteCollecteur({required String telephone, required String nom}) {
    return _comptesPreinscrits.doc(telephone).set({
      'nom': nom,
      'role': RoleUtilisateur.collecteur.valeur,
      'dateCreation': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<UserModel>> streamCollecteurs() {
    return _users
        .where('role', isEqualTo: RoleUtilisateur.collecteur.valeur)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList());
  }

  // ---------------------------------------------------------------------
  // Commandes
  // ---------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _commandes =>
      _db.collection(FirestoreCollections.commandes);

  Future<String> creerCommande(CommandeModel commande) async {
    final doc = await _commandes.add(commande.toMap());
    return doc.id;
  }

  Stream<List<CommandeModel>> streamCommandesClient(String clientId) {
    return _commandes
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommandeModel.fromMap(d.id, d.data())).toList());
  }

  /// Commandes dont la collecte reste à faire (vue collecteur).
  Stream<List<CommandeModel>> streamCommandesACollecter() {
    return _commandes
        .where('statut', whereIn: [
          StatutCommande.demandeCreee.valeur,
          StatutCommande.collectePlanifiee.valeur,
        ])
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommandeModel.fromMap(d.id, d.data())).toList());
  }

  /// Commandes prêtes à être livrées (vue collecteur).
  Stream<List<CommandeModel>> streamCommandesALivrer() {
    return _commandes
        .where('statut', whereIn: [
          StatutCommande.pret.valeur,
          StatutCommande.enLivraison.valeur,
        ])
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommandeModel.fromMap(d.id, d.data())).toList());
  }

  /// Toutes les commandes (vue gérant), avec filtre optionnel par statut.
  Stream<List<CommandeModel>> streamToutesCommandes({StatutCommande? filtreStatut}) {
    Query<Map<String, dynamic>> requete = _commandes.orderBy('dateCreation', descending: true);
    if (filtreStatut != null) {
      requete = requete.where('statut', isEqualTo: filtreStatut.valeur);
    }
    return requete
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommandeModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> mettreAJourStatut({
    required String commandeId,
    required StatutCommande nouveauStatut,
    String? collecteurId,
    Map<String, dynamic>? champsSupplementaires,
  }) {
    return _commandes.doc(commandeId).update({
      'statut': nouveauStatut.valeur,
      if (collecteurId != null) 'collecteurId': collecteurId,
      'historiqueStatuts': FieldValue.arrayUnion([
        {'statut': nouveauStatut.valeur, 'horodatage': Timestamp.now()}
      ]),
      ...?champsSupplementaires,
    });
  }

  Future<void> noterCommande(String commandeId, int etoiles) {
    return _commandes.doc(commandeId).update({'etoiles': etoiles});
  }

  // ---------------------------------------------------------------------
  // Tarifs
  // ---------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _tarifs =>
      _db.collection(FirestoreCollections.tarifs);

  Stream<List<TarifModel>> streamTarifs() {
    return _tarifs.snapshots().map(
          (snap) => snap.docs.map((d) => TarifModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> enregistrerTarif(TarifModel tarif) {
    return _tarifs.doc(tarif.typeService.valeur).set(tarif.toMap());
  }

  /// Crée une grille tarifaire de départ si la collection est vide, pour
  /// que le gérant ait quelque chose à éditer dès le premier lancement.
  Future<void> initialiserTarifsParDefautSiVide() async {
    final snap = await _tarifs.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final tarifsParDefaut = [
      const TarifModel(
        typeService: TypeService.standard,
        prixParKg: 750,
        description: 'Lavage + repassage standard',
      ),
      const TarifModel(
        typeService: TypeService.express24h,
        prixParKg: 1200,
        description: 'Lavage + repassage livré sous 24h',
      ),
      const TarifModel(
        typeService: TypeService.pressingPiece,
        prixParKg: 1500,
        description: 'Pressing à la pièce (costume, robe...)',
      ),
    ];
    final batch = _db.batch();
    for (final tarif in tarifsParDefaut) {
      batch.set(_tarifs.doc(tarif.typeService.valeur), tarif.toMap());
    }
    await batch.commit();
  }
}
