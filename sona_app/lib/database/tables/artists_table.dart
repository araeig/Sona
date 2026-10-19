import 'package:supabase_flutter/supabase_flutter.dart';

class ArtistsTable {
  final _supabase = Supabase.instance.client;

  Future<dynamic> getArtist(String artistId) async {
    try {
      final response = await _supabase
          .from('artists')
          .select()
          .eq('id', artistId)
          .single();
      return response;
    } catch (e) {
      print('GetArtist error: $e');
      return null;
    }
  }

  Future<List<dynamic>> getAllArtists() async {
    try {
      final response = await _supabase
          .from('artists')
          .select()
          .order('listener_count', ascending: false);
      return response;
    } catch (e) {
      print('GetAllArtists error: $e');
      return [];
    }
  }
}