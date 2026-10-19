import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/database/tables/tracks_table.dart';
import 'package:sona_app/database/tables/recommendations_table.dart';
import 'package:sona_app/database/tables/daily_mixes_table.dart';
import 'package:sona_app/services/ai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final TracksTable tracksTable = TracksTable();
  dynamic _featuredTrack;
  List<dynamic> _forYouTracks = [];
  List<dynamic> _newReleases = [];
  List<dynamic> _genres = [];
  List<Map<String, dynamic>> _dailyMixes = [];
  bool _isBuildingMixes = false;
  String? _selectedGenreId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  final RecommendationsTable recommendationsTable = RecommendationsTable();
  final DailyMixesTable dailyMixesTable = DailyMixesTable();
  final AiService aiService = AiService();

  Future<void> _loadData() async {
    final featured = await tracksTable.getFeaturedTrack();
    final tracks = await recommendationsTable.getForYou();
    final newReleases = await tracksTable.getNewReleases();
    final genres = await _supabase.from('genres').select();
    final dailyMixes = await dailyMixesTable.getForCurrentUser();
    if (!mounted) return;
    setState(() {
      _featuredTrack = featured;
      _forYouTracks = tracks;
      _newReleases = newReleases;
      _genres = genres;
      _dailyMixes = dailyMixes;
      _isLoading = false;
    });
  }

  Future<void> _buildDailyMixes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _isBuildingMixes) return;
    setState(() => _isBuildingMixes = true);
    final result = await aiService.buildDailyMixes(userId);
    if (result?['status'] == 'ok') {
      _dailyMixes = await dailyMixesTable.getForCurrentUser();
    }
    if (!mounted) return;
    setState(() => _isBuildingMixes = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not reach Sona AI. Check that the local server is running.',
          ),
        ),
      );
    } else if (result['status'] == 'not_enough_history') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listen to a few more tracks to build your mixes.'),
        ),
      );
    }
  }

  Widget _buildDailyMixesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily mixes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: _isBuildingMixes ? null : _buildDailyMixes,
                child: Text(
                  _dailyMixes.isEmpty ? 'Create' : 'Refresh',
                  style: const TextStyle(
                    color: Color(0xFFC4536A),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_dailyMixes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1015),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF251520)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFC4536A)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isBuildingMixes
                          ? 'Building mixes from your listening history…'
                          : 'Personal mixes made from your listening history.',
                      style: const TextStyle(
                        color: Color(0xFFB0A0A8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_isBuildingMixes)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFA0253F),
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 174,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _dailyMixes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final mix = _dailyMixes[index];
                final tracks = List<dynamic>.from(mix['tracks'] as List? ?? []);
                final coverUrl = mix['cover_url'] as String?;
                return GestureDetector(
                  onTap: tracks.isEmpty
                      ? null
                      : () => _goToPlayer(tracks.first, tracks),
                  child: Container(
                    width: 142,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1015),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF251520)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13),
                          ),
                          child: coverUrl == null
                              ? Container(
                                  width: 142,
                                  height: 108,
                                  color: const Color(0xFF251520),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFFA0253F),
                                    size: 32,
                                  ),
                                )
                              : Image.network(
                                  coverUrl,
                                  width: 142,
                                  height: 108,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 142,
                                    height: 108,
                                    color: const Color(0xFF251520),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: Color(0xFFA0253F),
                                      size: 32,
                                    ),
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
                          child: Text(
                            mix['name']?.toString() ?? 'Daily mix',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 3, 8, 0),
                          child: Text(
                            mix['subtitle']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB0A0A8),
                              fontSize: 10,
                            ),
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
    );
  }

  Future<void> _loadByGenre(String? genreId) async {
    setState(() => _isLoading = true);
    final tracks = genreId == null
        ? await recommendationsTable.getForYou()
        : await tracksTable.getTracksByGenre(genreId);
    if (!mounted) return;
    setState(() {
      _forYouTracks = tracks;
      _selectedGenreId = genreId;
      _isLoading = false;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _goToArtist(dynamic artist) {
    if (artist == null) return;
    Navigator.pushNamed(context, '/artist', arguments: artist);
  }

  void _goToPlayer(dynamic track, List<dynamic> queue) {
    print(
      'Going to player with track: ${track['title']}, audio_url: ${track['audio_url']}',
    );
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
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFA0253F)),
              )
            : RefreshIndicator(
                color: const Color(0xFFA0253F),
                backgroundColor: const Color(0xFF1A1015),
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Text(
                                  'What do you want to hear?',
                                  style: TextStyle(
                                    color: Color(0xFFB0A0A8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFA0253F),
                              ),
                              child: const Center(
                                child: Text(
                                  'AR',
                                  style: TextStyle(
                                    color: Color(0xFFfde8ed),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Genre pills
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _genres.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isActive = _selectedGenreId == null;
                              return GestureDetector(
                                onTap: () => _loadByGenre(null),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFA0253F)
                                        : const Color(0xFF1A1015),
                                    borderRadius: BorderRadius.circular(99),
                                    border: isActive
                                        ? null
                                        : Border.all(
                                            color: const Color(0xFF251520),
                                            width: 0.5,
                                          ),
                                  ),
                                  child: Text(
                                    'All',
                                    style: TextStyle(
                                      color: isActive
                                          ? const Color(0xFFfde8ed)
                                          : const Color(0xFFB0A0A8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final genre = _genres[index - 1];
                            final isActive = _selectedGenreId == genre['id'];
                            return GestureDetector(
                              onTap: () => _loadByGenre(genre['id']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFA0253F)
                                      : const Color(0xFF1A1015),
                                  borderRadius: BorderRadius.circular(99),
                                  border: isActive
                                      ? null
                                      : Border.all(
                                          color: const Color(0xFF251520),
                                          width: 0.5,
                                        ),
                                ),
                                child: Text(
                                  genre['name'],
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFFfde8ed)
                                        : const Color(0xFFB0A0A8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Featured card
                      if (_featuredTrack != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1015),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF251520),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _featuredTrack['cover_url'] != null
                                      ? Image.network(
                                          _featuredTrack['cover_url'],
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(
                                            width: double.infinity,
                                            height: 140,
                                            color: const Color(0xFF251520),
                                            child: const Icon(
                                              Icons.music_note,
                                              color: Color(0xFFA0253F),
                                              size: 48,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          height: 140,
                                          color: const Color(0xFF251520),
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Color(0xFFA0253F),
                                            size: 48,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'FEATURED TRACK',
                                  style: TextStyle(
                                    color: Color(0xFFC4536A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _featuredTrack['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _goToArtist(_featuredTrack['artists']),
                                  child: Text(
                                    _featuredTrack['artists']?['name'] ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFFB0A0A8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFA0253F),
                                    foregroundColor: const Color(0xFFfde8ed),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () => _goToPlayer(
                                    _featuredTrack,
                                    _forYouTracks,
                                  ),
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: const Text(
                                    'Play now',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildDailyMixesSection(),
                      const SizedBox(height: 16),
                      // For You header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'For you',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              'See all',
                              style: TextStyle(
                                color: Color(0xFFC4536A),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // For You horizontal scroll
                      SizedBox(
                        height: 136,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _forYouTracks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final track = _forYouTracks[index];
                            return GestureDetector(
                              onTap: () => _goToPlayer(track, _forYouTracks),
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1015),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF251520),
                                    width: 0.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      child: track['cover_url'] != null
                                          ? Image.network(
                                              track['cover_url'],
                                              width: 100,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  Container(
                                                    width: 100,
                                                    height: 80,
                                                    color: const Color(
                                                      0xFF251520,
                                                    ),
                                                    child: const Icon(
                                                      Icons.music_note,
                                                      color: Color(0xFFA0253F),
                                                    ),
                                                  ),
                                            )
                                          : Container(
                                              width: 100,
                                              height: 80,
                                              color: const Color(0xFF251520),
                                              child: const Icon(
                                                Icons.music_note,
                                                color: Color(0xFFA0253F),
                                              ),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            track['title'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          GestureDetector(
                                            onTap: () =>
                                                _goToArtist(track['artists']),
                                            child: Text(
                                              track['artists']?['name'] ?? '',
                                              style: const TextStyle(
                                                color: Color(0xFF6B5560),
                                                fontSize: 10,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // New Releases header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'New releases',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              'See all',
                              style: TextStyle(
                                color: Color(0xFFC4536A),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // New Releases list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _newReleases.length,
                        itemBuilder: (context, index) {
                          final track = _newReleases[index];
                          return GestureDetector(
                            onTap: () => _goToPlayer(track, _newReleases),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 4,
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
                                                  fit: BoxFit.cover,
                                                ),
                                          )
                                        : Image.asset(
                                            'images/default_cover.png',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
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
                                        GestureDetector(
                                          onTap: () =>
                                              _goToArtist(track['artists']),
                                          child: Text(
                                            track['artists']?['name'] ?? '',
                                            style: const TextStyle(
                                              color: Color(0xFFB0A0A8),
                                              fontSize: 11,
                                            ),
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
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
