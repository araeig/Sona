import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/database/tables/playlists_table.dart';

class CreatePlaylistPage extends StatefulWidget {
  const CreatePlaylistPage({super.key});

  @override
  State<CreatePlaylistPage> createState() => _CreatePlaylistPageState();
}

class _CreatePlaylistPageState extends State<CreatePlaylistPage> {
  final _supabase = Supabase.instance.client;
  final PlaylistsTable playlistsTable = PlaylistsTable();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();
  bool _isPrivate = true;
  bool _isLoading = false;

  final List<Color> _coverColors = [
    const Color(0xFFA0253F),
    const Color(0xFF185FA5),
    const Color(0xFF0F6E56),
    const Color(0xFF854F0B),
    const Color(0xFF534AB7),
    const Color(0xFF993C1D),
    const Color(0xFF3a2530),
    const Color(0xFF2C2C2A),
  ];
  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: const Color(0xFFfde8ed), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Color(0xFFfde8ed), fontSize: 13),
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
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar(
          'Please enter a playlist name', Icons.edit_outlined);
      return;
    }
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser!.id;
    await playlistsTable.createPlaylist(
      userId,
      _nameController.text.trim(),
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      _isPrivate,
    );
    setState(() => _isLoading = false);
    _showSnackBar(
        'Playlist created successfully!', Icons.check_circle_outline);
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 28),
                  ),
                  const Text(
                    'New playlist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : _createPlaylist,
                    child: Text(
                      'Create',
                      style: TextStyle(
                        color: _isLoading
                            ? const Color(0xFF6B5560)
                            : const Color(0xFFC4536A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Cover preview
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: _coverColors[_selectedColorIndex],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white30,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Colour picker
              const Text(
                'COVER COLOUR',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_coverColors.length, (index) {
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedColorIndex = index),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _coverColors[index],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Colors.white, width: 2.5)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Name
              const Text(
                'PLAYLIST NAME',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                cursorColor: const Color(0xFFC4536A),
                style: const TextStyle(color: Colors.white),
                maxLength: 50,
                decoration: InputDecoration(
                  hintText: 'My playlist',
                  hintStyle:
                      const TextStyle(color: Color(0xFF6B5560)),
                  filled: true,
                  fillColor: const Color(0xFF1A1015),
                  counterStyle: const TextStyle(
                      color: Color(0xFF6B5560), fontSize: 11),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFA0253F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF251520), width: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              const Text(
                'DESCRIPTION (OPTIONAL)',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                cursorColor: const Color(0xFFC4536A),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Add a description…',
                  hintStyle:
                      const TextStyle(color: Color(0xFF6B5560)),
                  filled: true,
                  fillColor: const Color(0xFF1A1015),
                  counterStyle: const TextStyle(
                      color: Color(0xFF6B5560), fontSize: 11),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFA0253F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF251520), width: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Privacy toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1015),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF251520), width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF251520),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFB0A0A8),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Private',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _isPrivate
                                ? 'Only you can see this playlist'
                                : 'Everyone can see this playlist',
                            style: const TextStyle(
                              color: Color(0xFF6B5560),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPrivate,
                      onChanged: (val) =>
                          setState(() => _isPrivate = val),
                      activeColor: const Color(0xFFA0253F),
                      activeTrackColor:
                          const Color(0xFFA0253F).withOpacity(0.3),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFF251520),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Create button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0253F),
                    foregroundColor: const Color(0xFFfde8ed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _createPlaylist,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFfde8ed))
                      : const Text(
                          'Create playlist',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
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
}