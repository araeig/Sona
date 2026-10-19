import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/database/tables/playlists_table.dart';
import 'package:sona_app/database/tables/liked_tracks_table.dart';
import 'package:sona_app/services/audio_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _supabase = Supabase.instance.client;
  final PlaylistsTable playlistsTable = PlaylistsTable();
  final LikedTracksTable likedTracksTable = LikedTracksTable();
  int _selectedTab = 0;
  List<dynamic> _playlists = [];
  List<dynamic> _likedTracks = [];
  List<dynamic> _publicPlaylists = [];
  List<dynamic> _history = [];
  List<dynamic> _followedArtists = [];
  bool _isLoading = true;

  final List<String> _tabs = [
    'Playlists',
    'Liked',
    'Artists',
    'History',
    'Public',
  ];

  final AudioPlayerService audioService = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    audioService.historyNotifier.addListener(_loadHistory);
    _loadData();
  }

  @override
  void dispose() {
    audioService.historyNotifier.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final userId = _supabase.auth.currentUser!.id;
    final history = await _supabase
        .from('play_history')
        .select('*, tracks(*, artists(id, name))')
        .eq('user_id', userId)
        .order('played_at', ascending: false)
        .limit(50);
    if (mounted) setState(() => _history = history);
  }

  Future<void> _loadData() async {
    final userId = _supabase.auth.currentUser!.id;
    final playlists = await playlistsTable.getUserPlaylists(userId);
    final liked = await likedTracksTable.getLikedTracks(userId);
    final publicPlaylists = await playlistsTable.getPublicPlaylists();
    final history = await _supabase
        .from('play_history')
        .select('*, tracks(*, artists(id, name))')
        .eq('user_id', userId)
        .order('played_at', ascending: false)
        .limit(50);
    final followedArtists = await _supabase
        .from('followed_artists')
        .select('*, artists(*)')
        .eq('user_id', userId);
    if (!mounted) return;
    setState(() {
      _playlists = playlists;
      _likedTracks = liked;
      _publicPlaylists = publicPlaylists;
      _history = history;
      _followedArtists = followedArtists;
      _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      const Text(
                        'My Library',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/create-playlist',
                      );
                      if (result == true) {
                        _loadData();
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1015),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF251520),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFFC4536A),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1015),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final isActive = _selectedTab == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFA0253F)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _tabs[index],
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFfde8ed)
                                    : const Color(0xFF6B5560),
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFA0253F),
                      ),
                    )
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPlaylists();
      case 1:
        return _buildLikedTracks();
      case 2:
        return _buildArtists();
      case 3:
        return _buildHistory();
      case 4:
        return _buildPublicPlaylists();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlaylists() {
    return RefreshIndicator(
      color: const Color(0xFFA0253F),
      backgroundColor: const Color(0xFF1A1015),
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                '/create-playlist',
              );
              if (result == true) {
                _loadData();
              }
            },
            child: Container(
              height: 64,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1015),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA0253F), width: 0.5),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF251520),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Color(0xFFC4536A),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create new playlist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Add your favourite tracks',
                        style: TextStyle(
                          color: Color(0xFF6B5560),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_playlists.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 48),
                child: Text(
                  'No playlists yet',
                  style: TextStyle(color: Color(0xFF6B5560)),
                ),
              ),
            )
          else
            ..._playlists.map((playlist) => _playlistTile(playlist)),
        ],
      ),
    );
  }

  Widget _playlistTile(dynamic playlist) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/playlist', arguments: playlist);
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1015),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF251520), width: 0.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: playlist['cover_url'] != null
                  ? Image.network(
                      playlist['cover_url'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Image.asset(
                        'images/default_playlist.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'images/default_playlist.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    playlist['is_private'] == true ? 'Private' : 'Public',
                    style: const TextStyle(
                      color: Color(0xFF6B5560),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B5560), size: 18),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedTracks() {
    if (_likedTracks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, color: Color(0xFF6B5560), size: 48),
            SizedBox(height: 12),
            Text(
              'No liked tracks yet',
              style: TextStyle(color: Color(0xFF6B5560)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _likedTracks.length,
      itemBuilder: (context, index) {
        final item = _likedTracks[index];
        final track = item['tracks'];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/player', arguments: track);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1015),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF251520), width: 0.5),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: track['cover_url'] != null
                      ? Image.network(
                          track['cover_url'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Image.asset(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        track['artists']?['name'] ?? '',
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
    );
  }

  Widget _buildArtists() {
    if (_followedArtists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Color(0xFF6B5560), size: 48),
            SizedBox(height: 12),
            Text(
              'No followed artists yet',
              style: TextStyle(color: Color(0xFF6B5560)),
            ),
            SizedBox(height: 4),
            Text(
              'Follow artists to see them here',
              style: TextStyle(color: Color(0xFF6B5560), fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _followedArtists.length,
      itemBuilder: (context, index) {
        final item = _followedArtists[index];
        final artist = item['artists'];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/artist', arguments: artist);
          },
          child: Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1015),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF251520), width: 0.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: artist['avatar_url'] != null
                      ? Image.network(
                          artist['avatar_url'],
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Image.asset(
                            'images/default_artist.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'images/default_artist.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_formatListeners(artist['listener_count'] ?? 0)} listeners',
                        style: const TextStyle(
                          color: Color(0xFF6B5560),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF6B5560),
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Color(0xFF6B5560), size: 48),
            SizedBox(height: 12),
            Text(
              'No listening history yet',
              style: TextStyle(color: Color(0xFF6B5560)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFA0253F),
      backgroundColor: const Color(0xFF1A1015),
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          final track = item['tracks'];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/player', arguments: track);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1015),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF251520), width: 0.5),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: track['cover_url'] != null
                        ? Image.network(
                            track['cover_url'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.asset(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          track['artists']?['name'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFF6B5560),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.history, color: Color(0xFF6B5560), size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPublicPlaylists() {
    if (_publicPlaylists.isEmpty) {
      return const Center(
        child: Text(
          'No public playlists yet',
          style: TextStyle(color: Color(0xFF6B5560)),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFA0253F),
      backgroundColor: const Color(0xFF1A1015),
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _publicPlaylists.length,
        itemBuilder: (context, index) {
          final playlist = _publicPlaylists[index];
          final isOwn = playlist['user_id'] == _supabase.auth.currentUser!.id;
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/playlist', arguments: playlist);
            },
            child: Container(
              height: 72,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1015),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF251520), width: 0.5),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: playlist['cover_url'] != null
                        ? Image.network(
                            playlist['cover_url'],
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.asset(
                              'images/default_playlist.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'images/default_playlist.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isOwn
                              ? 'You · Public'
                              : '@${playlist['profiles']?['username'] ?? ''} · Public',
                          style: const TextStyle(
                            color: Color(0xFF6B5560),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwn)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF251520),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Yours',
                        style: TextStyle(
                          color: Color(0xFFC4536A),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
