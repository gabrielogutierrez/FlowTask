import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? userName;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<bool> restore() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      userName = null;
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    userName =
        user.displayName ??
        prefs.getString('name') ??
        user.email?.split('@').first;

    return true;
  }

  Future<void> login(
    String email,
    String password,
  ) async {
    final credential =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Não foi possível entrar.');
    }

    userName =
        user.displayName ??
        user.email?.split('@').first ??
        'Usuário';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', userName!);
  }

  Future<void> register(
    String name,
    String email,
    String password,
  ) async {
    final credential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Não foi possível criar a conta.');
    }

    await user.updateDisplayName(name.trim());
    await user.reload();

    userName = name.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', userName!);
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();

    userName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name');
  }
}