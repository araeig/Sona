import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendationsTable {
  final _supabase = Supabase.instance.client;

  Future<List<dynamic>> getSimilarTracks(
    String trackId, {
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .rpc(
            'similar_tracks',
            params: {'p_track_id': trackId, 'p_limit': limit},
          )
          .select('*, artists(id, name, avatar_url)');
      return response;
    } catch (e) {
      print('GetSimilarTracks error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getRadioTracks(
    String trackId,
    List<String> excludeIds, {
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .rpc(
            'track_radio',
            params: {
              'p_track_id': trackId,
              'p_exclude': excludeIds,
              'p_limit': limit,
            },
          )
          .select('*, artists(id, name, avatar_url)');
      return response;
    } catch (e) {
      print('GetRadioTracks error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getForYou({int limit = 20}) async {
    try {
      final response = await _supabase
          .rpc('recommend_for_user', params: {'p_limit': limit})
          .select('*, artists(id, name, avatar_url)');
      return response;
    } catch (e) {
      print('GetForYou error: $e');
      return [];
    }
  }
}
