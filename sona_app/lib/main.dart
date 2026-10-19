import 'package:flutter/material.dart';
import 'package:sona_app/check.dart';
import 'package:sona_app/home.dart';
import 'package:sona_app/pages/artist_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/pages/auth/login_page.dart';
import 'package:sona_app/pages/auth/register_page.dart';
import 'package:sona_app/pages/auth/forgot_password_page.dart';
import 'package:sona_app/pages/genre_page.dart';
import 'package:sona_app/pages/player_page.dart';
import 'package:sona_app/pages/loading_page.dart';
import 'package:sona_app/pages/loading_to_home_page.dart';
import 'package:sona_app/pages/settings_page.dart';
import 'package:sona_app/pages/edit_profile_page.dart';
import 'package:sona_app/pages/change_password_page.dart';
import 'package:sona_app/pages/create_playlist_page.dart';
import 'package:sona_app/pages/playlist_page.dart';
import 'package:sona_app/pages/library_page.dart';
import 'package:sona_app/pages/mood_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://rxruakoorusxgdyqwrbo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4cnVha29vcnVzeGdkeXF3cmJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MjIxNjEsImV4cCI6MjA5MjE5ODE2MX0.9FGCUHVF_Un-J6fYi2W07vuIgXGZMnVSMM87tV1Nem4',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sona',
      theme: ThemeData.dark().copyWith(
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF3A1020),
          contentTextStyle: const TextStyle(
            color: Color(0xFFFDE8ED),
            fontSize: 13,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.all(16),
        ),
      ),
      initialRoute: '/',
      builder: (context, child) {
        return Container(
          color: const Color(0xFF0F0A0A),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child!,
            ),
          ),
        );
      },
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/genre': (context) {
          final genre = ModalRoute.of(context)!.settings.arguments;
          return GenrePage(genre: genre);
        },
        '/mood': (context) {
          final mood = ModalRoute.of(context)!.settings.arguments as String;
          return MoodPage(mood: mood);
        },
        '/artist': (context) {
          final artist = ModalRoute.of(context)!.settings.arguments;
          return ArtistPage(artist: artist);
        },
        '/player': (context) {
          final track = ModalRoute.of(context)!.settings.arguments;
          return PlayerPage(track: track);
        },
        '/edit-profile': (context) {
          final profile = ModalRoute.of(context)!.settings.arguments;
          return EditProfilePage(profile: profile);
        },
        '/playlist': (context) {
          final playlist = ModalRoute.of(context)!.settings.arguments;
          return PlaylistPage(playlist: playlist);
        },
        '/library': (context) => const LibraryScreen(),
        '/create-playlist': (context) => const CreatePlaylistPage(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/settings': (context) => const SettingsPage(),
        '/loading-to-home': (context) => const LoadingToHomePage(),
        '/': (context) => const LoadingPage(),
        '/check': (context) => const CheckPage(),
      },
    );
  }
}
