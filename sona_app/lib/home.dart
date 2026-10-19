import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:sona_app/pages/home_page.dart';
import 'package:sona_app/pages/search_page.dart';
import 'package:sona_app/pages/library_page.dart';
import 'package:sona_app/pages/profile_page.dart';
import 'package:sona_app/services/audio_service.dart';
import 'package:sona_app/pages/player_page.dart';

final ValueNotifier<int> homeTabNotifier = ValueNotifier<int>(0);

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _index;
  final AudioPlayerService audioService = AudioPlayerService();

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    homeTabNotifier.addListener(_onTabChange);
  }

  void _onTabChange() {
    setState(() {
      _index = homeTabNotifier.value;
    });
  }

  @override
  void dispose() {
    homeTabNotifier.removeListener(_onTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: _screens.elementAt(_index),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<dynamic>(
            valueListenable: audioService.currentTrackNotifier,
            builder: (context, currentTrack, child) {
              if (currentTrack == null) return const SizedBox();
              return StreamBuilder<bool>(
                stream: audioService.playingStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerPage(
                            track: {
                              'track': currentTrack,
                              'queue': audioService.queue,
                              'index': audioService.currentIndex,
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1015),
                        border: Border(
                          top: BorderSide(color: Color(0xFF251520), width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: currentTrack['cover_url'] != null
                                ? Image.network(
                                    currentTrack['cover_url'],
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 38,
                                      height: 38,
                                      color: const Color(0xFFA0253F),
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 38,
                                    height: 38,
                                    color: const Color(0xFFA0253F),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentTrack['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  currentTrack['artists']?['name'] ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFFB0A0A8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              audioService.togglePlayPause();
                              setState(() {});
                            },
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              await audioService.stop();
                              setState(() {});
                            },
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFF6B5560),
                              size: 20,
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
          SalomonBottomBar(
            currentIndex: _index,
            onTap: (index) {
              setState(() => _index = index);
              homeTabNotifier.value = index;
            },
            backgroundColor: const Color(0xFF0F0A0A),
            selectedItemColor: const Color(0xFFC4536A),
            unselectedItemColor: const Color(0xFF6B5560),
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                title: const Text('Home'),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.search),
                title: const Text('Search'),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.library_music_outlined),
                activeIcon: const Icon(Icons.library_music),
                title: const Text('Library'),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                title: const Text('Profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
