import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/database/authorize.dart';
import 'package:sona_app/database/tables/profiles_table.dart';
import 'package:sona_app/services/audio_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _supabase = Supabase.instance.client;
  final AuthService authService = AuthService();
  final ProfilesTable profilesTable = ProfilesTable();
  bool _newReleasesNotif = true;
  bool _recommendationsNotif = true;
  bool _systemAlerts = false;
  String _audioQuality = 'High';
  String _sleepTimer = 'Off';
  String _downloadQuality = 'Standard';
  double _bass = 0.0;
  double _mid = 0.0;
  double _treble = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = _supabase.auth.currentUser!.id;
    final profile = await _supabase
        .from('profiles')
        .select('settings')
        .eq('id', userId)
        .single();
    final settings = profile['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      setState(() {
        _audioQuality = settings['audioQuality'] ?? 'High';
        _sleepTimer = settings['sleepTimer'] ?? 'Off';
        _downloadQuality = settings['downloadQuality'] ?? 'Standard';
        _newReleasesNotif = settings['newReleasesNotif'] ?? true;
        _recommendationsNotif =
            settings['recommendationsNotif'] ?? true;
        _systemAlerts = settings['systemAlerts'] ?? false;
        _bass = (settings['bass'] ?? 0.0).toDouble();
        _mid = (settings['mid'] ?? 0.0).toDouble();
        _treble = (settings['treble'] ?? 0.0).toDouble();
      });
    }
  }

  Future<void> _saveSettings() async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('profiles').update({
      'settings': {
        'audioQuality': _audioQuality,
        'sleepTimer': _sleepTimer,
        'downloadQuality': _downloadQuality,
        'newReleasesNotif': _newReleasesNotif,
        'recommendationsNotif': _recommendationsNotif,
        'systemAlerts': _systemAlerts,
        'bass': _bass,
        'mid': _mid,
        'treble': _treble,
      }
    }).eq('id', userId);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1015),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete account',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: Color(0xFFB0A0A8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B5560)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFE24B4A)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      AudioPlayerService().stop();
      final userId = _supabase.auth.currentUser!.id;
      await profilesTable.updateProfile(userId, {
        'display_name': null,
        'username': null,
        'bio': null,
        'avatar_url': null,
      });
      await authService.logOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  }

  Future<void> _showChoiceDialog(
    String title,
    List<String> options,
    String current,
    Function(String) onSelected,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1015),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title,
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final isSelected = option == current;
            return ListTile(
              title: Text(
                option,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFC4536A)
                      : Colors.white,
                  fontWeight: isSelected
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check,
                      color: Color(0xFFC4536A), size: 18)
                  : null,
              onTap: () => Navigator.pop(context, option),
            );
          }).toList(),
        ),
      ),
    );
    if (result != null) onSelected(result);
  }

  Widget _eqSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB0A0A8),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFA0253F),
              inactiveTrackColor: const Color(0xFF251520),
              thumbColor: Colors.white,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: -10,
              max: 10,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toStringAsFixed(0)} dB',
            style: const TextStyle(
              color: Color(0xFF6B5560),
              fontSize: 11,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('ACCOUNT'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFFC4536A),
                      iconBg: const Color(0xFF251520),
                      title: 'Account info',
                      subtitle:
                          _supabase.auth.currentUser?.email ?? '',
                      onTap: () async {
                        final userId =
                            _supabase.auth.currentUser!.id;
                        final profile =
                            await profilesTable.getProfile(userId);
                        Navigator.pushNamed(
                          context,
                          '/edit-profile',
                          arguments: profile,
                        );
                      },
                      isFirst: true,
                      isLast: false,
                    ),
                    _menuItem(
                      icon: Icons.lock_outline,
                      iconColor: const Color(0xFFC4536A),
                      iconBg: const Color(0xFF251520),
                      title: 'Change password',
                      onTap: () => Navigator.pushNamed(
                          context, '/change-password'),
                      isFirst: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('PLAYBACK'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.audio_file_outlined,
                      iconColor: const Color(0xFFAFA9EC),
                      iconBg: const Color(0xFF1a1220),
                      title: 'Audio quality',
                      subtitle: 'Streaming & download',
                      trailing: Text(
                        _audioQuality,
                        style: const TextStyle(
                            color: Color(0xFFB0A0A8), fontSize: 12),
                      ),
                      onTap: () => _showChoiceDialog(
                        'Audio quality',
                        ['Low', 'Normal', 'High'],
                        _audioQuality,
                        (val) {
                          setState(() => _audioQuality = val);
                          _saveSettings();
                        },
                      ),
                      isFirst: true,
                      isLast: false,
                    ),
                    _menuItem(
                      icon: Icons.equalizer,
                      iconColor: const Color(0xFFAFA9EC),
                      iconBg: const Color(0xFF1a1220),
                      title: 'Equalizer',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: const Color(0xFF1A1015),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          builder: (context) => StatefulBuilder(
                            builder: (context, setModalState) =>
                                Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Equalizer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _eqSlider('Bass', _bass, (val) {
                                    setModalState(() => _bass = val);
                                    setState(() => _bass = val);
                                    _saveSettings();
                                  }),
                                  _eqSlider('Mid', _mid, (val) {
                                    setModalState(() => _mid = val);
                                    setState(() => _mid = val);
                                    _saveSettings();
                                  }),
                                  _eqSlider('Treble', _treble,
                                      (val) {
                                    setModalState(
                                        () => _treble = val);
                                    setState(() => _treble = val);
                                    _saveSettings();
                                  }),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style:
                                          ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFA0253F),
                                        foregroundColor:
                                            const Color(0xFFfde8ed),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  12),
                                        ),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text('Save'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      isFirst: false,
                      isLast: false,
                    ),
                    _menuItem(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFFAFA9EC),
                      iconBg: const Color(0xFF1a1220),
                      title: 'Sleep timer',
                      trailing: Text(
                        _sleepTimer,
                        style: const TextStyle(
                            color: Color(0xFFB0A0A8), fontSize: 12),
                      ),
                      onTap: () => _showChoiceDialog(
                        'Sleep timer',
                        ['Off', '15 min', '30 min', '1 hour'],
                        _sleepTimer,
                        (val) {
                          setState(() => _sleepTimer = val);
                          _saveSettings();
                        },
                      ),
                      isFirst: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('NOTIFICATIONS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _toggleItem(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFF5DCAA5),
                      iconBg: const Color(0xFF121a1f),
                      title: 'New releases',
                      subtitle: 'Artists you follow',
                      value: _newReleasesNotif,
                      onChanged: (val) {
                        setState(() => _newReleasesNotif = val);
                        _saveSettings();
                      },
                      isFirst: true,
                      isLast: false,
                    ),
                    _toggleItem(
                      icon: Icons.recommend_outlined,
                      iconColor: const Color(0xFF5DCAA5),
                      iconBg: const Color(0xFF121a1f),
                      title: 'Recommendations',
                      subtitle: 'Weekly picks for you',
                      value: _recommendationsNotif,
                      onChanged: (val) {
                        setState(
                            () => _recommendationsNotif = val);
                        _saveSettings();
                      },
                      isFirst: false,
                      isLast: false,
                    ),
                    _toggleItem(
                      icon: Icons.info_outline,
                      iconColor: const Color(0xFF5DCAA5),
                      iconBg: const Color(0xFF121a1f),
                      title: 'System alerts',
                      value: _systemAlerts,
                      onChanged: (val) {
                        setState(() => _systemAlerts = val);
                        _saveSettings();
                      },
                      isFirst: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('STORAGE'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.download_outlined,
                      iconColor: const Color(0xFFEF9F27),
                      iconBg: const Color(0xFF1a1a10),
                      title: 'Download quality',
                      trailing: Text(
                        _downloadQuality,
                        style: const TextStyle(
                            color: Color(0xFFB0A0A8), fontSize: 12),
                      ),
                      onTap: () => _showChoiceDialog(
                        'Download quality',
                        ['Low', 'Standard', 'High'],
                        _downloadQuality,
                        (val) {
                          setState(() => _downloadQuality = val);
                          _saveSettings();
                        },
                      ),
                      isFirst: true,
                      isLast: false,
                    ),
                    _menuItem(
                      icon: Icons.delete_outline,
                      iconColor: const Color(0xFFEF9F27),
                      iconBg: const Color(0xFF1a1a10),
                      title: 'Clear cache',
                      subtitle: 'Free up storage',
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            backgroundColor:
                                const Color(0xFF1A1015),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            content: const Row(
                              children: [
                                CircularProgressIndicator(
                                    color: Color(0xFFA0253F)),
                                SizedBox(width: 20),
                                Text(
                                  'Clearing cache…',
                                  style: TextStyle(
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                        await Future.delayed(
                            const Duration(seconds: 2));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Color(0xFFfde8ed),
                                    size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Cache cleared successfully',
                                    style: TextStyle(
                                        color: Color(0xFFfde8ed),
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor:
                                const Color(0xFF3a1020),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      isFirst: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('ACCOUNT ACTIONS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: _deleteAccount,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1015),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF3a1010),
                          width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3a1010),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_remove_outlined,
                            color: Color(0xFFE24B4A),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Delete account',
                          style: TextStyle(
                            color: Color(0xFFE24B4A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Sona v1.0.0 · Made with Flutter & Supabase',
                  style: TextStyle(
                    color: Color(0xFF6B5560),
                    fontSize: 11,
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

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6B5560),
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    required bool isFirst,
    required bool isLast,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1015),
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: isLast ? const Radius.circular(12) : Radius.zero,
          ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
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
            if (trailing != null) trailing,
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: Color(0xFF6B5560), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isFirst,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1015),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFA0253F),
            activeTrackColor:
                const Color(0xFFA0253F).withOpacity(0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF251520),
          ),
        ],
      ),
    );
  }
}