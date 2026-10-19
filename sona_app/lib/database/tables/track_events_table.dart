import 'package:supabase_flutter/supabase_flutter.dart';

class TrackEventsTable {
  final _supabase = Supabase.instance.client;

  Future<void> addEvent(
    String trackId,
    String eventType, {
    int? listenedSec,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('track_events').insert({
        'user_id': userId,
        'track_id': trackId,
        'event_type': eventType,
        'listened_sec': listenedSec,
      });
    } catch (e) {
      print('AddEvent error: $e');
    }
  }
}
