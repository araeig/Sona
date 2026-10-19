import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/database/tables/profiles_table.dart';
import 'package:file_picker/file_picker.dart';

class EditProfilePage extends StatefulWidget {
  final dynamic profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _supabase = Supabase.instance.client;
  final ProfilesTable profilesTable = ProfilesTable();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
        text: widget.profile?['display_name'] ?? '');
    _usernameController = TextEditingController(
        text: widget.profile?['username'] ?? '');
    _bioController =
        TextEditingController(text: widget.profile?['bio'] ?? '');
    _avatarUrl = widget.profile?['avatar_url'];
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    print('Avatar picker started');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      print('File picker result: $result');

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() => _isLoading = true);

      final userId = _supabase.auth.currentUser!.id;
      final fileName =
          'avatar_$userId.${file.extension ?? 'jpg'}';

      await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            file.bytes!,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(fileName);

      await profilesTable.updateProfile(userId, {
        'avatar_url': publicUrl,
      });

      setState(() {
        _avatarUrl = publicUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: Color(0xFFfde8ed), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Avatar updated successfully',
                  style: TextStyle(
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
    } catch (e) {
      print('Avatar upload error: $e'); // добавь
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline,
                  color: Color(0xFFfde8ed), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Failed to upload avatar. Please try again',
                  style: TextStyle(
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
  }

  Future<void> _saveProfile() async {
    if (_displayNameController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.edit_outlined,
                  color: Color(0xFFfde8ed), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Display name and username cannot be empty',
                  style: TextStyle(
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
      return;
    }
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser!.id;
    await profilesTable.updateProfile(userId, {
      'display_name': _displayNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
    });
    setState(() => _isLoading = false);
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Color(0xFFfde8ed), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Profile updated successfully',
                style: TextStyle(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 28),
                  ),
                  const Text(
                    'Edit profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : _saveProfile,
                    child: Text(
                      'Save',
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
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _pickAndUploadAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFA0253F),
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: _avatarUrl != null
                              ? Image.network(
                                  _avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
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
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFA0253F),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFFfde8ed),
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed:
                      _isLoading ? null : _pickAndUploadAvatar,
                  child: const Text(
                    'Change photo',
                    style: TextStyle(
                      color: Color(0xFFC4536A),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'DISPLAY NAME',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _displayNameController,
                cursorColor: const Color(0xFFC4536A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Your display name',
                  hintStyle:
                      const TextStyle(color: Color(0xFF6B5560)),
                  filled: true,
                  fillColor: const Color(0xFF1A1015),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFA0253F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF251520), width: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'USERNAME',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                cursorColor: const Color(0xFFC4536A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '@username',
                  hintStyle:
                      const TextStyle(color: Color(0xFF6B5560)),
                  filled: true,
                  fillColor: const Color(0xFF1A1015),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFA0253F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF251520), width: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'BIO',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                cursorColor: const Color(0xFFC4536A),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  hintText: 'Tell something about yourself…',
                  hintStyle:
                      const TextStyle(color: Color(0xFF6B5560)),
                  filled: true,
                  fillColor: const Color(0xFF1A1015),
                  counterStyle: const TextStyle(
                      color: Color(0xFF6B5560), fontSize: 11),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFA0253F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF251520), width: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'EMAIL',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1015),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF251520), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _supabase.auth.currentUser?.email ?? '',
                      style: const TextStyle(
                        color: Color(0xFF6B5560),
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Read only',
                      style: TextStyle(
                        color: Color(0xFF6B5560),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFfde8ed))
                      : const Text(
                          'Save changes',
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