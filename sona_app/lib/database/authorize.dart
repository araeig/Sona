import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<User?> signIn(String email, String password) async {
    try {
      AuthResponse authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return authResponse.user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> signUp(String email, String password) async {
    AuthResponse authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    return authResponse.user;
  }

  Future<void> logOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      return;
    }
  }

  Future<void> recoveryPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      return;
    }
  }
}
