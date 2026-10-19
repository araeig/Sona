import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;
  bool _oldPassVisible = false;
  bool _newPassVisible = false;
  bool _confirmPassVisible = false;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
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

  Future<void> _changePassword() async {
    if (_oldPassController.text.isEmpty ||
        _newPassController.text.isEmpty ||
        _confirmPassController.text.isEmpty) {
      _showSnackBar(
          'Please fill in all fields', Icons.edit_outlined);
      return;
    }
    if (_newPassController.text.length < 6) {
      _showSnackBar(
          'New password must be at least 6 characters',
          Icons.lock_outline);
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      _showSnackBar(
          'Passwords do not match', Icons.error_outline);
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Проверяем старый пароль через повторный вход
      final email = _supabase.auth.currentUser?.email ?? '';
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: _oldPassController.text,
      );
      if (response.user == null) {
        _showSnackBar(
            'Current password is incorrect', Icons.lock_outline);
        setState(() => _isLoading = false);
        return;
      }
      // Меняем пароль
      await _supabase.auth.updateUser(
        UserAttributes(password: _newPassController.text),
      );
      setState(() => _isLoading = false);
      // Показываем успех
      _showSnackBar(
          'Password changed successfully!',
          Icons.check_circle_outline);
      // Ждём 3 секунды и переходим назад
      await Future.delayed(const Duration(seconds: 3));
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (e.toString().contains('invalid_credentials') ||
          e.toString().contains('Invalid login credentials')) {
        _showSnackBar(
            'Current password is incorrect', Icons.lock_outline);
      } else {
        _showSnackBar(
            'Something went wrong. Please try again',
            Icons.error_outline);
      }
    }
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
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Change password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF251520),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFFC4536A),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Create a new password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Your new password must be at least 6 characters',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB0A0A8),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Current password
              const Text(
                'CURRENT PASSWORD',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _oldPassController,
                obscureText: !_oldPassVisible,
                cursorColor: const Color(0xFFC4536A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle:
                      const TextStyle(color: Color(0xFF6B5560)),
                  filled: true,
                  fillColor: const Color(0xFF1A1015),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(
                        () => _oldPassVisible = !_oldPassVisible),
                    child: Icon(
                      _oldPassVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF6B5560),
                      size: 20,
                    ),
                  ),
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
              // New password
              const Text(
                'NEW PASSWORD',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPassController,
                obscureText: !_newPassVisible,
                cursorColor: const Color(0xFFC4536A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle:
                      const TextStyle(color: Color(0xFF6B5560)),
                  filled: true,
                  fillColor: const Color(0xFF1A1015),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(
                        () => _newPassVisible = !_newPassVisible),
                    child: Icon(
                      _newPassVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF6B5560),
                      size: 20,
                    ),
                  ),
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
              // Confirm password
              const Text(
                'CONFIRM NEW PASSWORD',
                style: TextStyle(
                  color: Color(0xFF6B5560),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPassController,
                obscureText: !_confirmPassVisible,
                cursorColor: const Color(0xFFC4536A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle:
                      const TextStyle(color: Color(0xFF6B5560)),
                  filled: true,
                  fillColor: const Color(0xFF1A1015),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() =>
                        _confirmPassVisible = !_confirmPassVisible),
                    child: Icon(
                      _confirmPassVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF6B5560),
                      size: 20,
                    ),
                  ),
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
              const SizedBox(height: 32),
              // Save button
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
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFfde8ed))
                      : const Text(
                          'Change password',
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