import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:utility_tools/services/app_settings.dart';

class FfmpegService {
  /// Singleton
  FfmpegService._privateConstructor();
  static final FfmpegService instance = FfmpegService._privateConstructor();

  /// Current running process for streaming / cancel
  Process? _currentProcess;
  bool _isCancelled = false;

  /// Get FFmpeg path from settings
  String get ffmpegPath => AppSettings.ffmpegPath;

  /// Generic run (non-streaming)
  Future<ProcessResult> run(List<String> args) async {
    final path = ffmpegPath;
    if (path.isEmpty) throw Exception('FFmpeg path not set');

    try {
      final result = await Process.run(path, args);
      if (result.exitCode != 0) {
        throw Exception('FFmpeg failed: ${result.stderr}');
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Generic streaming run (line by line) with cancel support
  Stream<String> runStream(List<String> args) async* {
    final path = ffmpegPath;
    if (path.isEmpty) {
      yield '[FFmpeg path not set]';
      return;
    }

    _isCancelled = false;

    try {
      final process = await Process.start(path, args, runInShell: true);
      _currentProcess = process;

      // Stream stderr (FFmpeg logs progress here)
      await for (final line
          in process.stderr
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (_isCancelled) {
          process.kill(ProcessSignal.sigkill);
          yield '[Cancelled]';
          break;
        }
        yield line + '\n';
      }

      final exitCode = await process.exitCode;
      if (!_isCancelled) {
        if (exitCode == 0) {
          yield '[FFmpeg finished successfully]';
        } else {
          yield '[FFmpeg error: exit code $exitCode]';
        }
      }
    } catch (e) {
      yield '[FFmpeg exception: $e]';
    } finally {
      _currentProcess = null;
    }
  }

  /// Cancel current running process
  void cancel() {
    _isCancelled = true;
    _currentProcess?.kill(ProcessSignal.sigkill);
  }

  /// Convert video to GIF (non-streaming)
  Future<File> videoToGif(
    File video,
    File outputGif, {
    int startSecond = 0,
    int duration = 5,
    int width = 320,
    int fps = 10,
  }) async {
    final args = [
      '-y',
      '-ss',
      startSecond.toString(),
      '-t',
      duration.toString(),
      '-i',
      video.path,
      '-vf',
      'fps=$fps,scale=$width:-1:flags=lanczos',
      outputGif.path,
    ];

    await run(args);
    return outputGif;
  }

  /// Extract a single frame (non-streaming)
  Future<File> extractFrame(
    File video,
    File outputImage, {
    int second = 0,
  }) async {
    final args = [
      '-y',
      '-ss',
      second.toString(),
      '-i',
      video.path,
      '-vframes',
      '1',
      outputImage.path,
    ];

    await run(args);
    return outputImage;
  }

  /// Check FFmpeg version
  Future<String> version() async {
    final result = await run(['-version']);
    return result.stdout.toString();
  }

  /// Optional: video to GIF streaming version
  Stream<String> videoToGifStream(
    File video,
    File outputGif, {
    int startSecond = 0,
    int duration = 5,
    int width = 320,
    int fps = 10,
  }) {
    final args = [
      '-y',
      '-ss',
      startSecond.toString(),
      '-t',
      duration.toString(),
      '-i',
      video.path,
      '-vf',
      'fps=$fps,scale=$width:-1:flags=lanczos',
      outputGif.path,
    ];

    return runStream(args);
  }
}
