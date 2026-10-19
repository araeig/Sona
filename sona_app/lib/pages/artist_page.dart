import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/database/tables/followed_artists_table.dart';

class ArtistPage extends StatefulWidget {
  final dynamic artist;

  const ArtistPage({super.key, required this.artist});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  final _supabase = Supabase.instance.client;
  final FollowedArtistsTable followedArtistsTable = FollowedArtistsTable();
  dynamic _artist;
  List<dynamic> _tracks = [];
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = _supabase.auth.currentUser!.id;
    final artistId = widget.artist['id'];

    final artistFuture = _supabase
        .from('artists')
        .select('*, artist_genres(genres(name))')
        .eq('id', artistId)
        .single();

    final tracksFuture = _supabase
        .from('tracks')
        .select('*, artists(id, name)')
        .eq('artist_id', artistId)
        .order('play_count', ascending: false);

    final followingFuture = followedArtistsTable.isFollowing(userId, artistId);

    final artistData = await artistFuture;
    final tracks = await tracksFuture;
    final isFollowing = await followingFuture;

    setState(() {
      _artist = artistData;
      _tracks = tracks;
      _isFollowing = isFollowing;
      _isLoading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final userId = _supabase.auth.currentUser!.id;
    final artistId = widget.artist['id'];
    if (_isFollowing) {
      await followedArtistsTable.unfollowArtist(userId, artistId);
    } else {
      await followedArtistsTable.followArtist(userId, artistId);
    }
    final artistData = await _supabase
        .from('artists')
        .select('*, artist_genres(genres(name))')
        .eq('id', artistId)
        .single();
    if (!mounted) return;
    setState(() {
      _isFollowing = !_isFollowing;
      _artist = artistData;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatListeners(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _getGenres() {
    if (_artist?['artist_genres'] == null) return '';
    final genres = _artist['artist_genres'] as List;
    if (genres.isEmpty) return '';
    return genres.map((ag) => ag['genres']['name']).join(' · ');
  }

  void _goToPlayer(dynamic track) {
    final index = _tracks.indexOf(track);
    Navigator.pushNamed(
      context,
      '/player',
      arguments: {
        'track': track,
        'queue': _tracks,
        'index': index >= 0 ? index : 0,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final artist = _artist ?? widget.artist;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFA0253F)),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero
                    Container(
                      width: double.infinity,
                      height: 220,
                      color: const Color(0xFF1f1018),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: artist['avatar_url'] != null
                                ? Image.network(
                                    artist['avatar_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Image.asset(
                                      'images/default_artist.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'images/default_artist.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF0F0A0A),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 24,
                            right: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artist['name'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_getGenres().isNotEmpty)
                                  Text(
                                    _getGenres(),
                                    style: const TextStyle(
                                      color: Color(0xFFB0A0A8),
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stats row
                    Container(
                      color: const Color(0xFF1A1015),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            _formatListeners(artist['listener_count'] ?? 0),
                            'Listeners',
                          ),
                          _divider(),
                          _statItem('${_tracks.length}', 'Tracks'),
                          _divider(),
                          _statItem('1', 'Albums'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Follow + Play buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? const Color(0xFF1A1015)
                                    : const Color(0xFFA0253F),
                                foregroundColor: _isFollowing
                                    ? const Color(0xFFC4536A)
                                    : const Color(0xFFfde8ed),
                                side: _isFollowing
                                    ? const BorderSide(color: Color(0xFFA0253F))
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _toggleFollow,
                              child: Text(
                                _isFollowing ? 'Following' : 'Follow',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _tracks.isEmpty
                                ? null
                                : () => _goToPlayer(_tracks[0]),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1015),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFF251520),
                                  width: 0.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1015),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFF251520),
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.more_vert,
                              color: Color(0xFFB0A0A8),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Popular tracks
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Popular tracks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final track = _tracks[index];
                        return GestureDetector(
                          onTap: () => _goToPlayer(track),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1015),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF251520),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFFA0253F),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: track['cover_url'] != null
                                      ? Image.network(
                                          track['cover_url'],
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              Image.asset(
                                                'images/default_cover.png',
                                                width: 40,
                                                height: 40,
                                              ),
                                        )
                                      : Image.asset(
                                          'images/default_cover.png',
                                          width: 40,
                                          height: 40,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track['title'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${_formatListeners(track['play_count'] ?? 0)} plays',
                                        style: const TextStyle(
                                          color: Color(0xFF6B5560),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDuration(track['duration_sec'] ?? 0),
                                  style: const TextStyle(
                                    color: Color(0xFF6B5560),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B5560), fontSize: 11),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 0.5, height: 28, color: const Color(0xFF251520));
  }
}
