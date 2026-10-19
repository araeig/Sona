import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/database/tables/track_events_table.dart';

class LikedTracksTable {
  final _supabase = Supabase.instance.client;

  Future<List<dynamic>> getLikedTracks(String userId) async {
    try {
      final response = await _supabase
          .from('liked_tracks')
          .select('*, tracks(*, artists(id, name))')
          .eq('user_id', userId)
          .order('liked_at', ascending: false);
      print('Liked tracks response: $response');
      return response;
    } catch (e) {
      print('GetLikedTracks error: $e');
      return [];
    }
  }

  Future<void> likeTrack(String userId, String trackId) async {
    try {
      await _supabase.from('liked_tracks').insert({
        'user_id': userId,
        'track_id': trackId,
      });
      await TrackEventsTable().addEvent(trackId, 'like');
    } catch (e) {
      print('LikeTrack error: $e');
    }
  }

  Future<void> unlikeTrack(String userId, String trackId) async {
    try {
      await _supabase
          .from('liked_tracks')
          .delete()
          .eq('user_id', userId)
          .eq('track_id', trackId);
    } catch (e) {
      print('UnlikeTrack error: $e');
    }
  }

  Future<bool> isLiked(String userId, String trackId) async {
    try {
      final response = await _supabase
          .from('liked_tracks')
          .select()
          .eq('user_id', userId)
          .eq('track_id', trackId);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
