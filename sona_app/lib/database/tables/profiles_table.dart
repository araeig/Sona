import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilesTable {
  final _supabase = Supabase.instance.client;

  Future<void> createProfile(
    String userId,
    String displayName,
    String username,
  ) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'display_name': displayName,
        'username': username,
      });
    } catch (e) {
      print('CreateProfile error: $e');
      return;
    }
  }

  Future<dynamic> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      return;
    }
  }
}
