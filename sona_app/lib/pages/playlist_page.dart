import 'package:flutter/material.dart';
import 'package:sona_app/database/tables/playlists_table.dart';

class PlaylistPage extends StatefulWidget {
  final dynamic playlist;

  const PlaylistPage({super.key, required this.playlist});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final PlaylistsTable playlistsTable = PlaylistsTable();
  List<dynamic> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks =
        await playlistsTable.getPlaylistTracks(widget.playlist['id']);
    setState(() {
      _tracks = tracks;
      _isLoading = false;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _goToPlayer(dynamic track) {
    final queue = _tracks.map((item) => item['tracks']).toList();
    final index = queue.indexOf(track);
    Navigator.pushNamed(
      context,
      '/player',
      arguments: {
        'track': track,
        'queue': queue,
        'index': index >= 0 ? index : 0,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      playlist['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Playlist cover + info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: playlist['cover_url'] != null
                        ? Image.network(
                            playlist['cover_url'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.asset(
                              'images/default_playlist.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'images/default_playlist.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playlist['description'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFFB0A0A8),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_tracks.length} tracks · ${playlist['is_private'] == true ? 'Private' : 'Public'}',
                          style: const TextStyle(
                            color: Color(0xFF6B5560),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Play button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0253F),
                    foregroundColor: const Color(0xFFfde8ed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _tracks.isEmpty
                      ? null
                      : () {
                          final firstTrack = _tracks[0]['tracks'];
                          _goToPlayer(firstTrack);
                        },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text(
                    'Play all',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: Color(0xFF251520)),
            ),
            // Tracks
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFA0253F)),
                    )
                  : _tracks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_off,
                                  color: Color(0xFF6B5560),
                                  size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'No tracks in this playlist yet',
                                style: TextStyle(
                                    color: Color(0xFF6B5560)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24),
                          itemCount: _tracks.length,
                          itemBuilder: (context, index) {
                            final item = _tracks[index];
                            final track = item['tracks'];
                            return GestureDetector(
                              onTap: () => _goToPlayer(track),
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 8),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1015),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          const Color(0xFF251520),
                                      width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B5560),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: track['cover_url'] !=
                                              null
                                          ? Image.network(
                                              track['cover_url'],
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (c, e, s) =>
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
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            track['title'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w500,
                                            ),
                                            overflow: TextOverflow
                                                .ellipsis,
                                          ),
                                          Text(
                                            track['artists']
                                                    ?['name'] ??
                                                '',
                                            style: const TextStyle(
                                              color:
                                                  Color(0xFF6B5560),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(
                                          track['duration_sec'] ??
                                              0),
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
            ),
          ],
        ),
      ),
    );
  }
}