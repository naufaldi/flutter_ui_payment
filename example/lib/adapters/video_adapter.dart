import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:video_player/video_player.dart';

/// Adapts the official `video_player` plugin to [PaymentVideoController].
///
/// This is the only place in the repository that depends on a media plugin.
/// A host can write the same ~80 lines for any other player.
class VideoPlayerAdapter extends PaymentVideoController {
  VideoPlayerAdapter.asset(this.asset, {this.errorMessage});

  final String asset;

  /// Safe message shown when playback fails; raw player errors are logged
  /// by the host, never displayed.
  final String? errorMessage;

  VideoPlayerController? _player;

  @override
  Future<void> initialize() async {
    await _player?.dispose();
    value = value.copyWith(phase: VideoPhase.loading, errorMessage: () => null);
    final player = VideoPlayerController.asset(
      asset,
      // Never interrupts music or other audio the person is playing.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _player = player;
    player.addListener(_sync);
    try {
      await player.initialize();
      if (_player != player) return;
      value = value.copyWith(
        phase: VideoPhase.ready,
        duration: player.value.duration,
        aspectRatio: player.value.aspectRatio,
      );
    } catch (_) {
      if (_player != player) return;
      value = value.copyWith(
        phase: VideoPhase.error,
        errorMessage: () => errorMessage,
      );
    }
  }

  void _sync() {
    final p = _player?.value;
    if (p == null || !p.isInitialized) return;
    if (p.hasError) {
      value = value.copyWith(
        phase: VideoPhase.error,
        errorMessage: () => errorMessage,
      );
      return;
    }
    final ended =
        p.duration > Duration.zero && p.position >= p.duration && !p.isPlaying;
    final phase = ended
        ? VideoPhase.ended
        : p.isBuffering && p.isPlaying
        ? VideoPhase.buffering
        : p.isPlaying
        ? VideoPhase.playing
        : (value.phase == VideoPhase.ready
              ? VideoPhase.ready
              : VideoPhase.paused);
    value = value.copyWith(
      phase: phase,
      position: p.position,
      duration: p.duration,
      muted: p.volume == 0,
    );
  }

  @override
  Future<void> play() async => _player?.play();

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> seekTo(Duration position) async {
    await _player?.seekTo(position);
    _sync();
  }

  @override
  Future<void> setMuted(bool muted) async {
    await _player?.setVolume(muted ? 0 : 1);
    value = value.copyWith(muted: muted);
  }

  @override
  Future<void> retry() => initialize();

  @override
  Widget buildSurface(BuildContext context) {
    final player = _player;
    return player == null ? const SizedBox.shrink() : VideoPlayer(player);
  }

  @override
  void dispose() {
    final player = _player;
    _player = null;
    player?.removeListener(_sync);
    unawaited(player?.dispose());
    super.dispose();
  }
}
