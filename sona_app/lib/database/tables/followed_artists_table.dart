import 'package:supabase_flutter/supabase_flutter.dart';

class FollowedArtistsTable {
  final _supabase = Supabase.instance.client;

  Future<bool> isFollowing(String userId, String artistId) async {
    try {
      final response = await _supabase
          .from('followed_artists')
          .select()
          .eq('user_id', userId)
          .eq('artist_id', artistId);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> followArtist(String userId, String artistId) async {
    try {
      await _supabase.from('followed_artists').insert({
        'user_id': userId,
        'artist_id': artistId,
      });
    } catch (e) {
      print('FollowArtist error: $e');
    }
  }

  Future<void> unfollowArtist(String userId, String artistId) async {
    try {
      await _supabase
          .from('followed_artists')
          .delete()
          .eq('user_id', userId)
          .eq('artist_id', artistId);
    } catch (e) {
      print('UnfollowArtist error: $e');
    }
  }

  Future<List<dynamic>> getFollowedArtists(String userId) async {
    try {
      final response = await _supabase
          .from('followed_artists')
          .select('*, artists(*)')
          .eq('user_id', userId);
      return response;
    } catch (e) {
      print('GetFollowedArtists error: $e');
      return [];
    }
  }
}