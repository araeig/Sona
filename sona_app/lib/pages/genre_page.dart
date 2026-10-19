import 'package:flutter/material.dart';
import 'package:sona_app/database/tables/tracks_table.dart';

class GenrePage extends StatefulWidget {
  final dynamic genre;

  const GenrePage({super.key, required this.genre});

  @override
  State<GenrePage> createState() => _GenrePageState();
}

class _GenrePageState extends State<GenrePage> {
  final TracksTable tracksTable = TracksTable();
  List<dynamic> _tracks = [];
  bool _isLoading = true;

  final Map<String, Color> _genreColors = {
    'Hip-hop': const Color(0xFF3a1020),
    'R&B': const Color(0xFF0e1f2a),
    'Pop': const Color(0xFF1a1a0a),
    'Electronic': const Color(0xFF0a1a18),
    'Jazz': const Color(0xFF1a120a),
    'Indie': const Color(0xFF1a0a1a),
  };

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks = await tracksTable.getTracksByGenre(
      widget.genre['id'],
    );
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

  @override
  Widget build(BuildContext context) {
    final genreName = widget.genre['name'] ?? '';
    final bgColor = _genreColors[genreName] ?? const Color(0xFF1a1015);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(color: bgColor),
              child: Stack(
                children: [
                  Positioned(
                    right: 24,
                    bottom: 16,
                    child: Row(
                      children: List.generate(6, (i) {
                        final heights = [60.0, 80.0, 50.0, 90.0, 70.0, 55.0];
                        return Container(
                          width: 8,
                          height: heights[i],
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA0253F)
                                .withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          genreName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_tracks.length} tracks',
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
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA0253F),
                        foregroundColor: const Color(0xFFfde8ed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Play all',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
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
                          color: const Color(0xFF251520), width: 0.5),
                    ),
                    child: const Icon(Icons.shuffle,
                        color: Color(0xFFB0A0A8), size: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFA0253F)),
                    )
                  : _tracks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tracks in this genre yet',
                            style:
                                TextStyle(color: Color(0xFF6B5560)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24),
                          itemCount: _tracks.length,
                          itemBuilder: (context, index) {
                            final track = _tracks[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1015),
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF251520),
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
                                            fontWeight:
                                                FontWeight.w500,
                                          ),
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          track['artists']
                                                  ?['name'] ??
                                              '',
                                          style: const TextStyle(
                                            color: Color(0xFF6B5560),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(
                                        track['duration_sec'] ?? 0),
                                    style: const TextStyle(
                                      color: Color(0xFF6B5560),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
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