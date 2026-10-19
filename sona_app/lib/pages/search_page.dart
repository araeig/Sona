import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/services/ai_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _supabase = Supabase.instance.client;
  final AiService _aiService = AiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _allTracks = [];
  bool _isTracksLoading = true;
  List<dynamic> _vibeTracks = [];
  bool _isVibeLoading = false;

  final List<Color> _genreColors = [
    const Color(0xFF3a1020),
    const Color(0xFF0e1f2a),
    const Color(0xFF1a1a0a),
    const Color(0xFF0a1a18),
    const Color(0xFF1a120a),
    const Color(0xFF1a0a1a),
  ];

  final Map<String, IconData> _moods = {
    'calm': Icons.spa_outlined,
    'energetic': Icons.bolt,
    'happy': Icons.wb_sunny_outlined,
    'sad': Icons.water_drop_outlined,
    'dark': Icons.nightlight_outlined,
    'romantic': Icons.favorite_border,
    'dreamy': Icons.cloud_outlined,
    'aggressive': Icons.local_fire_department_outlined,
    'epic': Icons.landscape_outlined,
    'groovy': Icons.graphic_eq,
  };

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final response = await _supabase
          .from('tracks')
          .select('*, artists(id, name, avatar_url)')
          .order('play_count', ascending: false);
      if (mounted) {
        setState(() {
          _allTracks = response;
          _isTracksLoading = false;
        });
      }
    } catch (e) {
      print('LoadTracks error: $e');
      if (mounted) setState(() => _isTracksLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _vibeTracks = [];
        _isVibeLoading = false;
      });
      return;
    }
    setState(() => _isVibeLoading = true);
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchByVibe(query),
    );
  }

  Future<void> _searchByVibe(String query) async {
    final tracks = await _aiService.searchByDescription(query);
    if (!mounted || _searchController.text.trim() != query) return;
    setState(() {
      _vibeTracks = tracks;
      _isVibeLoading = false;
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _vibeTracks = [];
      _isVibeLoading = false;
    });
  }

  List<dynamic> _textMatches() {
    final query = _searchController.text.trim().toLowerCase();
    return _allTracks.where((track) {
      final title = (track['title'] ?? '').toString().toLowerCase();
      final artist = (track['artists']?['name'] ?? '').toString().toLowerCase();
      return title.contains(query) || artist.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                cursorColor: const Color(0xFFC4536A),
                style: const TextStyle(color: Colors.white),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Songs, artists or describe a vibe…',
                  hintStyle: const TextStyle(color: Color(0xFF6B5560)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6B5560),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF6B5560),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1A1015),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA0253F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF251520),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildBrowse()
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowse() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Browse genres',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder(
              stream: _supabase.from('genres').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFA0253F)),
                  );
                }
                final genres = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    final color = _genreColors[index % _genreColors.length];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/genre',
                          arguments: genre,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              genre['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Browse by mood',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
              itemCount: _moods.length,
              itemBuilder: (context, index) {
                final mood = _moods.keys.elementAt(index);
                final color = _genreColors[(index + 3) % _genreColors.length];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/mood', arguments: mood);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${mood[0].toUpperCase()}${mood.substring(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          _moods[mood],
                          color: const Color(0xFFC4536A),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Trending now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isTracksLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFA0253F)),
            )
          else if (_allTracks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'No tracks yet',
                style: TextStyle(color: Color(0xFF6B5560)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allTracks.length > 5 ? 5 : _allTracks.length,
              itemBuilder: (context, index) {
                return _trackTile(_allTracks[index], index + 1);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isTracksLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA0253F)),
      );
    }

    final textMatches = _textMatches();
    final textIds = textMatches.map((track) => track['id']).toSet();
    final vibeTracks = _vibeTracks
        .where((track) => !textIds.contains(track['id']))
        .toList();

    if (textMatches.isEmpty && vibeTracks.isEmpty && !_isVibeLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Color(0xFF6B5560), size: 48),
            const SizedBox(height: 12),
            Text(
              'No results for "${_searchController.text}"',
              style: const TextStyle(color: Color(0xFF6B5560), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        ...textMatches.asMap().entries.map(
          (entry) => _trackTile(entry.value, entry.key + 1),
        ),
        if (_isVibeLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC4536A),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Searching by vibe…',
                  style: TextStyle(color: Color(0xFF6B5560), fontSize: 12),
                ),
              ],
            ),
          ),
        if (!_isVibeLoading && vibeTracks.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              textMatches.isEmpty ? 0 : 20,
              24,
              8,
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFC4536A), size: 16),
                SizedBox(width: 8),
                Text(
                  'Matches your vibe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ...vibeTracks.asMap().entries.map(
            (entry) =>
                _trackTile(entry.value, entry.key + 1, queue: vibeTracks),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _trackTile(dynamic track, int index, {List<dynamic>? queue}) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/player',
          arguments: queue != null
              ? {'track': track, 'queue': queue, 'index': index - 1}
              : track,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1015),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF251520), width: 0.5),
          ),
          child: Row(
            children: [
              Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFFA0253F),
                  fontSize: 12,
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
                        errorBuilder: (c, e, s) => Image.asset(
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
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/artist',
                          arguments: track['artists'],
                        );
                      },
                      child: Text(
                        track['artists']?['name'] ?? '',
                        style: const TextStyle(
                          color: Color(0xFF6B5560),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDuration(track['duration_sec'] ?? 0),
                style: const TextStyle(color: Color(0xFF6B5560), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
