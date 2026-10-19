import 'package:supabase_flutter/supabase_flutter.dart';

class DailyMixesTable {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getForCurrentUser() async {
    try {
      final mixes = await _supabase
          .from('daily_mixes')
          .select('id, name, subtitle, cover_url, position')
          .order('position');

      final result = <Map<String, dynamic>>[];
      for (final mix in mixes) {
        final rows = await _supabase
            .from('daily_mix_tracks')
            .select('position, tracks(*, artists(id, name, avatar_url))')
            .eq('mix_id', mix['id'])
            .order('position');
        final tracks = rows
            .map((row) => row['tracks'])
            .whereType<Map<String, dynamic>>()
            .toList();
        result.add({...mix, 'tracks': tracks});
      }
      return result;
    } catch (e) {
      print('GetDailyMixes error: $e');
      return [];
    }
  }
}
