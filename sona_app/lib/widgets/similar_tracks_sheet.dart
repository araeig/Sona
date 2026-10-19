import 'package:flutter/material.dart';
import 'package:sona_app/database/tables/recommendations_table.dart';
import 'package:sona_app/services/audio_service.dart';

class SimilarTracksSheet extends StatefulWidget {
  final dynamic track;
  final Future<void> Function() onTrackChanged;

  const SimilarTracksSheet({
    super.key,
    required this.track,
    required this.onTrackChanged,
  });

  @override
  State<SimilarTracksSheet> createState() => _SimilarTracksSheetState();
}

class _SimilarTracksSheetState extends State<SimilarTracksSheet> {
  final RecommendationsTable recommendationsTable = RecommendationsTable();
  final AudioPlayerService audioService = AudioPlayerService();
  List<dynamic> _tracks = [];
  bool _isLoading = true;
  bool _isStartingRadio = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks = await recommendationsTable.getSimilarTracks(
      widget.track['id'],
    );
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  Future<void> _playTrack(int index) async {
    await audioService.playTrack(_tracks[index], queue: _tracks, index: index);
    await widget.onTrackChanged();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _startRadio() async {
    setState(() => _isStartingRadio = true);
    final started = await audioService.startRadio(widget.track);
    await widget.onTrackChanged();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              started ? Icons.radio : Icons.error_outline,
              color: const Color(0xFFfde8ed),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              started
                  ? 'Radio started'
                  : 'Radio is not available for this track',
              style: const TextStyle(color: Color(0xFFfde8ed), fontSize: 13),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3a1020),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Similar tracks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: _isStartingRadio ? null : _startRadio,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA0253F)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isStartingRadio
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFC4536A),
                              ),
                            )
                          : const Icon(
                              Icons.radio,
                              color: Color(0xFFC4536A),
                              size: 16,
                            ),
                      const SizedBox(width: 6),
                      const Text(
                        'Start radio',
                        style: TextStyle(
                          color: Color(0xFFC4536A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFFA0253F)),
          )
        else if (_tracks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No similar tracks yet',
              style: TextStyle(color: Color(0xFF6B5560)),
            ),
          )
        else
          SizedBox(
            height: 360,
            child: ListView.builder(
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: track['cover_url'] != null
                        ? Image.network(
                            track['cover_url'],
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFF251520),
                            child: const Icon(
                              Icons.music_note,
                              color: Color(0xFF6B5560),
                            ),
                          ),
                  ),
                  title: Text(
                    track['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    track['artists']?['name'] ?? '',
                    style: const TextStyle(color: Color(0xFF6B5560)),
                  ),
                  onTap: () => _playTrack(index),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
