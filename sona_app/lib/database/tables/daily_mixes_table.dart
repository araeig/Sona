import 'package:supabase_flutter/supabase_flutter.dart';

class DailyMixesTable {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getForCurrentUser() async {
    try {
      final mixes = await _supabase
          .from('daily_mixes')
          .select(
            'id, name, subtitle, cover_url, position, '
            'daily_mix_tracks(position, tracks(*, artists(id, name, avatar_url)))',
          )
          .order('position');

      return mixes.map((mix) {
        final rows =
            List<Map<String, dynamic>>.from(
              mix['daily_mix_tracks'] as List? ?? const [],
            )..sort(
              (a, b) => (a['position'] as int).compareTo(b['position'] as int),
            );
        final tracks = rows
            .map((row) => row['tracks'])
            .whereType<Map<String, dynamic>>()
            .toList();
        return <String, dynamic>{...mix, 'tracks': tracks};
      }).toList();
    } catch (e) {
      print('GetDailyMixes error: $e');
      return [];
    }
  }
}
