import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/database/authorize.dart';
import 'package:sona_app/database/tables/profiles_table.dart';
import 'package:sona_app/services/audio_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final AuthService authService = AuthService();
  final ProfilesTable profilesTable = ProfilesTable();
  dynamic _profile;
  bool _isLoading = true;
  int _likedCount = 0;
  int _playlistsCount = 0;
  int _artistsCount = 0;
  int _playedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser!.id;
    final profile = await profilesTable.getProfile(userId);
    final liked = await _supabase
        .from('liked_tracks')
        .select()
        .eq('user_id', userId);
    final playlists = await _supabase
        .from('playlists')
        .select()
        .eq('user_id', userId);
    final artists = await _supabase
        .from('followed_artists')
        .select()
        .eq('user_id', userId);
    final history = await _supabase
        .from('play_history')
        .select()
        .eq('user_id', userId);
    setState(() {
      _profile = profile;
      _likedCount = liked.length;
      _playlistsCount = playlists.length;
      _artistsCount = artists.length;
      _playedCount = history.length;
      _isLoading = false;
    });
  }

  String _getMemberYear() {
    if (_profile?['created_at'] == null) return '';
    final date = DateTime.parse(_profile['created_at']);
    return date.year.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFA0253F)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
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
                          Icons.settings_outlined,
                          color: Color(0xFFB0A0A8),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFA0253F),
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: _profile?['avatar_url'] != null
                      ? Image.network(
                          _profile['avatar_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'images/default_avatar.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'images/default_avatar.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _profile?['display_name'] ?? 'No name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${_profile?['username'] ?? ''} · member since ${_getMemberYear()}',
                style: const TextStyle(
                    color: Color(0xFFB0A0A8), fontSize: 13),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC4536A),
                  side: const BorderSide(color: Color(0xFFA0253F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                ),
                onPressed: () async {
                  await Navigator.pushNamed(
                    context,
                    '/edit-profile',
                    arguments: _profile,
                  );
                  _loadProfile();
                },
                child: const Text(
                  'Edit profile',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1015),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF251520),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('$_playedCount', 'Played'),
                      _divider(),
                      _statItem('$_likedCount', 'Liked'),
                      _divider(),
                      _statItem('$_playlistsCount', 'Playlists'),
                      _divider(),
                      _statItem('$_artistsCount', 'Artists'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.favorite_outline,
                      iconColor: const Color(0xFFC4536A),
                      iconBg: const Color(0xFF1f1018),
                      title: 'Liked songs',
                      subtitle: '$_likedCount tracks',
                      onTap: () {
                        Navigator.pushNamed(context, '/library');
                      },
                    ),
                    const SizedBox(height: 2),
                    _menuItem(
                      icon: Icons.library_music_outlined,
                      iconColor: const Color(0xFF5DCAA5),
                      iconBg: const Color(0xFF121a1f),
                      title: 'My playlists',
                      subtitle: '$_playlistsCount playlists',
                      onTap: () {
                        Navigator.pushNamed(context, '/library');
                      },
                    ),
                    const SizedBox(height: 2),
                    _menuItem(
                      icon: Icons.people_outline,
                      iconColor: const Color(0xFFEF9F27),
                      iconBg: const Color(0xFF1a1a12),
                      title: 'Following artists',
                      subtitle: '$_artistsCount artists',
                      onTap: () {
                        Navigator.pushNamed(context, '/library');
                      },
                    ),
                    const SizedBox(height: 2),
                    _menuItem(
                      icon: Icons.settings_outlined,
                      iconColor: const Color(0xFFB0A0A8),
                      iconBg: const Color(0xFF1A1015),
                      title: 'Settings',
                      subtitle: 'Notifications, quality',
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC4536A),
                      side: const BorderSide(
                        color: Color(0xFF3a1520),
                        width: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      AudioPlayerService().stop();
                      await authService.logOut();
                      final prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', false);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Log out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
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
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              color: Color(0xFF6B5560), fontSize: 11),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
        width: 0.5, height: 32, color: const Color(0xFF251520));
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1015),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF251520), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B5560),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF6B5560), size: 18),
          ],
        ),
      ),
    );
  }
}