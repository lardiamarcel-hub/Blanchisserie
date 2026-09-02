import 'package:firebase_auth/firebase_auth.dart';

/// Encapsule la connexion par numéro de téléphone + code OTP SMS.
///
/// Le numéro doit être fourni au format international (ex: +226XXXXXXXX)
/// car Firebase Auth ne fait pas de résolution d'indicatif automatique.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> get changementsUtilisateur => _auth.authStateChanges();

  User? get utilisateurActuel => _auth.currentUser;

  /// Démarre la vérification du numéro de téléphone.
  ///
  /// - [surCodeEnvoye] est appelé dès que le SMS a été envoyé, avec
  ///   l'identifiant de vérification à réutiliser dans [confirmerCodeOtp].
  /// - [surEchec] est appelé en cas d'erreur (numéro invalide, quota SMS…).
  /// - Sur certains téléphones Android, Firebase peut valider automatiquement
  ///   le SMS sans que l'utilisateur ait à saisir le code : dans ce cas
  ///   [surValidationAutomatique] est appelé directement.
  Future<void> demarrerVerificationTelephone({
    required String numeroTelephone,
    required void Function(String identifiantVerification) surCodeEnvoye,
    required void Function(FirebaseAuthException erreur) surEchec,
    required void Function() surValidationAutomatique,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: numeroTelephone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        surValidationAutomatique();
      },
      verificationFailed: surEchec,
      codeSent: (String identifiantVerification, int? forceResendingToken) {
        surCodeEnvoye(identifiantVerification);
      },
      codeAutoRetrievalTimeout: (String identifiantVerification) {},
    );
  }

  /// Valide le code OTP saisi par l'utilisateur et termine la connexion.
  Future<UserCredential> confirmerCodeOtp({
    required String identifiantVerification,
    required String code,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: identifiantVerification,
      smsCode: code,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> deconnexion() => _auth.signOut();
}
