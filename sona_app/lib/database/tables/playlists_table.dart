import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistsTable {
  final _supabase = Supabase.instance.client;

  Future<List<dynamic>> getUserPlaylists(String userId) async {
    try {
      final response = await _supabase
          .from('playlists')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      print('GetUserPlaylists error: $e');
      return [];
    }
  }

  Future<void> createPlaylist(
    String userId,
    String name,
    String? description,
    bool isPrivate,
  ) async {
    try {
      await _supabase.from('playlists').insert({
        'user_id': userId,
        'name': name,
        'description': description,
        'is_private': isPrivate,
      });
    } catch (e) {
      print('CreatePlaylist error: $e');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _supabase.from('playlists').delete().eq('id', playlistId);
    } catch (e) {
      print('DeletePlaylist error: $e');
    }
  }

  Future<List<dynamic>> getPlaylistTracks(String playlistId) async {
    try {
      final response = await _supabase
          .from('playlist_tracks')
          .select('*, tracks(*, artists(name))')
          .eq('playlist_id', playlistId)
          .order('position');
      return response;
    } catch (e) {
      print('GetPlaylistTracks error: $e');
      return [];
    }
  }

  Future<void> addTrackToPlaylist(
    String playlistId,
    String trackId,
    int position,
  ) async {
    try {
      await _supabase.from('playlist_tracks').insert({
        'playlist_id': playlistId,
        'track_id': trackId,
        'position': position,
      });
    } catch (e) {
      print('AddTrackToPlaylist error: $e');
    }
  }

  Future<List<dynamic>> getPublicPlaylists() async {
    try {
      final response = await _supabase
          .from('playlists')
          .select('*, profiles(display_name, username)')
          .eq('is_private', false)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      print('GetPublicPlaylists error: $e');
      return [];
    }
  }
}
