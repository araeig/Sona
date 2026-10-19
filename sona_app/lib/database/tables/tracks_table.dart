import 'package:supabase_flutter/supabase_flutter.dart';

class TracksTable {
  final _supabase = Supabase.instance.client;

  Future<List<dynamic>> getAllTracks() async {
    try {
      final response = await _supabase
          .from('tracks')
          .select('*, artists(id, name, avatar_url)') // добавь id
          .order('play_count', ascending: false);
      return response;
    } catch (e) {
      print('GetAllTracks error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getTracksByGenre(String genreId) async {
    try {
      final response = await _supabase
          .from('tracks')
          .select('*, artists(id, name, avatar_url)') // добавь id
          .eq('genre_id', genreId)
          .order('play_count', ascending: false);
      return response;
    } catch (e) {
      print('GetTracksByGenre error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getTracksByMood(String mood) async {
    try {
      final response = await _supabase
          .from('tracks')
          .select('*, artists(id, name, avatar_url)')
          .contains('mood_tags', [mood])
          .order('play_count', ascending: false);
      return response;
    } catch (e) {
      print('GetTracksByMood error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getNewReleases() async {
    try {
      final response = await _supabase
          .from('tracks')
          .select('*, artists(id, name, avatar_url)') // добавь id
          .order('created_at', ascending: false)
          .limit(10);
      return response;
    } catch (e) {
      print('GetNewReleases error: $e');
      return [];
    }
  }

  Future<dynamic> getFeaturedTrack() async {
    try {
      final response = await _supabase
          .from('tracks')
          .select('*, artists(id, name, avatar_url)') // добавь id
          .order('play_count', ascending: false)
          .limit(1)
          .single();
      return response;
    } catch (e) {
      print('GetFeaturedTrack error: $e');
      return null;
    }
  }
}
