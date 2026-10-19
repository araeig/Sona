import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sona_app/database/tables/recommendations_table.dart';
import 'package:sona_app/database/tables/track_events_table.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final _supabase = Supabase.instance.client;
  final RecommendationsTable _recommendationsTable = RecommendationsTable();
  final TrackEventsTable _trackEventsTable = TrackEventsTable();
  final ValueNotifier<dynamic> currentTrackNotifier = ValueNotifier<dynamic>(
    null,
  );
  final ValueNotifier<int> historyNotifier = ValueNotifier<int>(0);
  dynamic _currentTrack;
  List<dynamic> _queue = [];
  int _currentIndex = 0;
  bool _isRadio = false;
  bool _isExtendingRadio = false;

  AudioPlayer get player => _player;
  dynamic get currentTrack => _currentTrack;
  List<dynamic> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _player.playing;
  bool get isRadio => _isRadio;
  bool get hasPrevious => _currentIndex > 0;
  bool get hasNext => _currentIndex < _queue.length - 1;

  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> playTrack(
    dynamic track, {
    List<dynamic>? queue,
    int? index,
  }) async {
    try {
      if (queue != null) {
        if (!identical(queue, _queue)) {
          _isRadio = false;
        }
        _queue = queue;
        _currentIndex = index ?? 0;
      } else if (_queue.isEmpty) {
        _queue = [track];
        _currentIndex = 0;
      }
      final audioUrl = track['audio_url'];
      if (audioUrl == null) {
        print(
          'AudioPlayerService: audio_url is null for track: ${track['title']}',
        );
        return;
      }
      if (_currentTrack != null && _currentTrack['id'] != track['id']) {
        _logListening(_currentTrack);
      }
      _currentTrack = track;
      currentTrackNotifier.value = track;
      _extendRadioIfNeeded();
      await _player.setUrl(audioUrl);
      await _player.play();
      await _recordHistory(track);
    } catch (e) {
      print('AudioPlayerService error: $e');
    }
  }

  void _logListening(dynamic track) {
    final listened = _player.position.inSeconds;
    final duration = track['duration_sec'] ?? 0;
    final isPlay = listened >= 30 || (duration > 0 && listened >= duration / 2);
    _trackEventsTable.addEvent(
      track['id'],
      isPlay ? 'play' : 'skip',
      listenedSec: listened,
    );
  }

  Future<bool> startRadio(dynamic seedTrack) async {
    final tracks = await _recommendationsTable.getRadioTracks(seedTrack['id'], [
      seedTrack['id'],
    ]);
    if (tracks.isEmpty) return false;
    final queue = [seedTrack, ...tracks];
    if (_currentTrack?['id'] == seedTrack['id']) {
      _queue = queue;
      _currentIndex = 0;
    } else {
      await playTrack(seedTrack, queue: queue, index: 0);
    }
    _isRadio = true;
    return true;
  }

  Future<void> _extendRadioIfNeeded() async {
    if (!_isRadio || _isExtendingRadio) return;
    if (_queue.length - _currentIndex - 1 > 2) return;
    _isExtendingRadio = true;
    try {
      final excludeIds = _queue.map((t) => t['id'] as String).toList();
      final tracks = await _recommendationsTable.getRadioTracks(
        _currentTrack['id'],
        excludeIds,
      );
      if (_isRadio) {
        _queue = [..._queue, ...tracks];
      }
    } catch (e) {
      print('ExtendRadio error: $e');
    }
    _isExtendingRadio = false;
  }

  Future<void> _onTrackCompleted() async {
    if (hasNext) {
      await playNext();
    }
  }

  Future<void> playNext() async {
    if (!hasNext) return;
    _currentIndex++;
    await playTrack(_queue[_currentIndex]);
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    _currentIndex--;
    await playTrack(_queue[_currentIndex]);
  }

  Future<void> _recordHistory(dynamic track) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('play_history').insert({
        'user_id': userId,
        'track_id': track['id'],
      });
      historyNotifier.value++;
    } catch (e) {
      print('RecordHistory error: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    if (_currentTrack != null) {
      _logListening(_currentTrack);
    }
    await _player.stop();
    _currentTrack = null;
    currentTrackNotifier.value = null;
    _queue = [];
    _currentIndex = 0;
    _isRadio = false;
  }

  void dispose() {
    _player.dispose();
  }

  void setQueue(List<dynamic> queue, int index) {
    if (!identical(queue, _queue)) {
      _isRadio = false;
    }
    _queue = queue;
    _currentIndex = index;
  }
}
