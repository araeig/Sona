import 'package:flutter/material.dart';
import 'package:sona_app/services/audio_service.dart';
import 'package:sona_app/database/tables/liked_tracks_table.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/widgets/similar_tracks_sheet.dart';

class PlayerPage extends StatefulWidget {
  final dynamic track;

  const PlayerPage({super.key, required this.track});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final AudioPlayerService audioService = AudioPlayerService();
  final LikedTracksTable likedTracksTable = LikedTracksTable();
  final _supabase = Supabase.instance.client;
  bool _isLiked = false;
  bool _isLoading = true;
  dynamic _track;

  @override
  void initState() {
    super.initState();
    audioService.currentTrackNotifier.addListener(_updateTrackInfo);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    audioService.currentTrackNotifier.removeListener(_updateTrackInfo);
    super.dispose();
  }

  Future<void> _init() async {
    final userId = _supabase.auth.currentUser!.id;

    if (widget.track is Map && (widget.track as Map).containsKey('queue')) {
      _track = widget.track['track'];
      final queue = widget.track['queue'] as List<dynamic>;
      final index = widget.track['index'] as int;
      if (audioService.currentTrack?['id'] != _track['id']) {
        audioService.playTrack(_track, queue: queue, index: index);
      } else {
        audioService.setQueue(queue, index);
      }
    } else {
      _track = widget.track;
      if (audioService.currentTrack?['id'] != _track['id']) {
        audioService.playTrack(_track);
      }
    }

    final isLiked = await likedTracksTable.isLiked(userId, _track['id']);

    if (mounted) {
      setState(() {
        _isLiked = isLiked;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTrackInfo() async {
    final userId = _supabase.auth.currentUser!.id;
    final newTrack = audioService.currentTrack;
    if (newTrack == null) return;
    final isLiked = await likedTracksTable.isLiked(userId, newTrack['id']);
    if (mounted) {
      setState(() {
        _track = newTrack;
        _isLiked = isLiked;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final userId = _supabase.auth.currentUser!.id;
    final trackId = _track['id'];
    if (_isLiked) {
      await likedTracksTable.unlikeTrack(userId, trackId);
    } else {
      await likedTracksTable.likeTrack(userId, trackId);
    }
    setState(() => _isLiked = !_isLiked);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showAddToPlaylist() async {
    final userId = _supabase.auth.currentUser!.id;
    final playlists = await _supabase
        .from('playlists')
        .select()
        .eq('user_id', userId);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1015),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Add to playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No playlists yet',
                style: TextStyle(color: Color(0xFF6B5560)),
              ),
            )
          else
            ...playlists.map(
              (playlist) => ListTile(
                leading: const Icon(
                  Icons.library_music_outlined,
                  color: Color(0xFFC4536A),
                ),
                title: Text(
                  playlist['name'] ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await _supabase.from('playlist_tracks').insert({
                    'playlist_id': playlist['id'],
                    'track_id': _track['id'],
                    'position': 0,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFFfde8ed),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Added to ${playlist['name']}',
                            style: const TextStyle(
                              color: Color(0xFFfde8ed),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF3a1020),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = _track;

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
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Column(
                            children: [
                              const Text(
                                'Now playing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (track['artists'] != null) {
                                    Navigator.pushNamed(
                                      context,
                                      '/artist',
                                      arguments: track['artists'],
                                    );
                                  }
                                },
                                child: Text(
                                  track['artists']?['name'] ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFFC4536A),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.more_vert,
                            color: Color(0xFFB0A0A8),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cover
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: track['cover_url'] != null
                              ? Image.network(
                                  track['cover_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: const Color(0xFF1A1015),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Color(0xFFA0253F),
                                      size: 80,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFF1A1015),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Color(0xFFA0253F),
                                    size: 80,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Track info + like
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (track['artists'] != null) {
                                      Navigator.pushNamed(
                                        context,
                                        '/artist',
                                        arguments: track['artists'],
                                      );
                                    }
                                  },
                                  child: Text(
                                    track['artists']?['name'] ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFFB0A0A8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked
                                  ? const Color(0xFFA0253F)
                                  : const Color(0xFFB0A0A8),
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: StreamBuilder<Duration>(
                        stream: audioService.positionStream,
                        builder: (context, positionSnapshot) {
                          return StreamBuilder<Duration?>(
                            stream: audioService.durationStream,
                            builder: (context, durationSnapshot) {
                              final position =
                                  positionSnapshot.data ?? Duration.zero;
                              final duration =
                                  durationSnapshot.data ?? Duration.zero;
                              final progress = duration.inMilliseconds > 0
                                  ? position.inMilliseconds /
                                        duration.inMilliseconds
                                  : 0.0;
                              return Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: const Color(0xFFA0253F),
                                      inactiveTrackColor: const Color(
                                        0xFF251520,
                                      ),
                                      thumbColor: Colors.white,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 12,
                                          ),
                                      trackHeight: 3,
                                    ),
                                    child: Slider(
                                      value: progress.clamp(0.0, 1.0),
                                      onChanged: (value) {
                                        final newPosition = Duration(
                                          milliseconds:
                                              (value * duration.inMilliseconds)
                                                  .round(),
                                        );
                                        audioService.seekTo(newPosition);
                                      },
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: const TextStyle(
                                          color: Color(0xFF6B5560),
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: const TextStyle(
                                          color: Color(0xFF6B5560),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: StreamBuilder<bool>(
                        stream: audioService.playingStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(
                                Icons.shuffle,
                                color: Color(0xFF6B5560),
                                size: 24,
                              ),
                              // Previous
                              GestureDetector(
                                onTap: () async {
                                  if (audioService.hasPrevious) {
                                    audioService.playPrevious();
                                    await Future.delayed(
                                      const Duration(milliseconds: 300),
                                    );
                                    await _updateTrackInfo();
                                  }
                                },
                                child: Icon(
                                  Icons.skip_previous,
                                  color: audioService.hasPrevious
                                      ? Colors.white
                                      : const Color(0xFF6B5560),
                                  size: 36,
                                ),
                              ),
                              // Play/Pause
                              GestureDetector(
                                onTap: audioService.togglePlayPause,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFA0253F),
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: const Color(0xFFfde8ed),
                                    size: 32,
                                  ),
                                ),
                              ),
                              // Next
                              GestureDetector(
                                onTap: () async {
                                  if (audioService.hasNext) {
                                    audioService.playNext();
                                    await Future.delayed(
                                      const Duration(milliseconds: 300),
                                    );
                                    await _updateTrackInfo();
                                  }
                                },
                                child: Icon(
                                  Icons.skip_next,
                                  color: audioService.hasNext
                                      ? Colors.white
                                      : const Color(0xFF6B5560),
                                  size: 36,
                                ),
                              ),
                              const Icon(
                                Icons.repeat,
                                color: Color(0xFF6B5560),
                                size: 24,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Extra actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: const Color(0xFF1A1015),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'Queue',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (audioService.queue.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Queue is empty',
                                          style: TextStyle(
                                            color: Color(0xFF6B5560),
                                          ),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 300,
                                        child: ListView.builder(
                                          itemCount: audioService.queue.length,
                                          itemBuilder: (context, index) {
                                            final qTrack =
                                                audioService.queue[index];
                                            final isCurrent =
                                                index ==
                                                audioService.currentIndex;
                                            return ListTile(
                                              leading: Icon(
                                                isCurrent
                                                    ? Icons.play_arrow
                                                    : Icons.music_note,
                                                color: isCurrent
                                                    ? const Color(0xFFC4536A)
                                                    : const Color(0xFF6B5560),
                                              ),
                                              title: Text(
                                                qTrack['title'] ?? '',
                                                style: TextStyle(
                                                  color: isCurrent
                                                      ? const Color(0xFFC4536A)
                                                      : Colors.white,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              subtitle: Text(
                                                qTrack['artists']?['name'] ??
                                                    '',
                                                style: const TextStyle(
                                                  color: Color(0xFF6B5560),
                                                ),
                                              ),
                                              onTap: () async {
                                                await audioService.playTrack(
                                                  qTrack,
                                                  queue: audioService.queue,
                                                  index: index,
                                                );
                                                await _updateTrackInfo();
                                                Navigator.pop(context);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              );
                            },
                            child: _extraButton(Icons.queue_music, 'Queue'),
                          ),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: const Color(0xFF1A1015),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) => SimilarTracksSheet(
                                  track: _track,
                                  onTrackChanged: _updateTrackInfo,
                                ),
                              );
                            },
                            child: _extraButton(Icons.auto_awesome, 'Similar'),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: _extraButton(Icons.share, 'Share'),
                          ),
                          GestureDetector(
                            onTap: _showAddToPlaylist,
                            child: _extraButton(
                              Icons.playlist_add,
                              'Add to playlist',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _extraButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6B5560), size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B5560), fontSize: 11),
        ),
      ],
    );
  }
}
