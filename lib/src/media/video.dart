import '../controls/actions.dart';
import 'package:flutter/material.dart';

import '../foundation/focus_ring.dart';
import '../foundation/primitives.dart';
import '../foundation/payment_tokens.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_motion.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';

/// Where a video is in its lifecycle.
enum VideoPhase {
  idle,
  loading,
  ready,
  buffering,
  playing,
  paused,
  ended,
  error,
}

/// A snapshot of playback that a [PaymentVideoController] publishes.
@immutable
class VideoPlaybackValue {
  const VideoPlaybackValue({
    this.phase = VideoPhase.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.muted = false,
    this.aspectRatio,
    this.errorMessage,
  });

  final VideoPhase phase;
  final Duration position;
  final Duration duration;
  final bool muted;

  /// Width / height of the decoded video, once known.
  final double? aspectRatio;

  /// Safe, user-facing message. Never a raw player or network error.
  final String? errorMessage;

  bool get isPlaying => phase == VideoPhase.playing;

  VideoPlaybackValue copyWith({
    VideoPhase? phase,
    Duration? position,
    Duration? duration,
    bool? muted,
    double? aspectRatio,
    String? Function()? errorMessage,
  }) => VideoPlaybackValue(
    phase: phase ?? this.phase,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    muted: muted ?? this.muted,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    errorMessage: errorMessage == null ? this.errorMessage : errorMessage(),
  );
}

/// Bridge between [PaymentVideoPlayer] and the host's media engine.
///
/// The kit ships no media plugin. A host adapts its player of choice (the
/// example uses the official `video_player` package) by extending this class,
/// updating [value] as playback changes and implementing the commands. The
/// host creates and disposes the controller; the widget never disposes it.
abstract class PaymentVideoController
    extends ValueNotifier<VideoPlaybackValue> {
  PaymentVideoController([super.value = const VideoPlaybackValue()]);

  /// Loads the media. Called by the widget once when [value] is idle.
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setMuted(bool muted);

  /// Starts over after an error.
  Future<void> retry();

  /// Renders the current frame. Called only when the media is loaded.
  Widget buildSurface(BuildContext context);
}

/// Video with accessible controls below the picture.
///
/// - Never starts by itself unless [autoPlay] is set, and not even then when
///   the platform asks for reduced motion.
/// - Pauses when the app goes to the background, when the widget is hidden
///   (an inactive `IndexedStack` tab, a covered route, `TickerMode(false)`)
///   and when it is removed. It does not resume on its own: people press play again.
/// - Controls sit below the picture rather than over it, so they never hide
///   content, keep their contrast on any frame and stay usable at 200% text.
class PaymentVideoPlayer extends StatefulWidget {
  const PaymentVideoPlayer({
    super.key,
    required this.controller,
    required this.title,
    this.poster,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
  });

  final PaymentVideoController controller;

  /// Describes the video for screen readers, e.g. "How to pay with QRIS".
  final String title;

  /// Shown before the first frame is ready.
  final Widget? poster;

  /// Used until the media reports its own ratio.
  final double aspectRatio;
  final bool autoPlay;

  @override
  State<PaymentVideoPlayer> createState() => _PaymentVideoPlayerState();
}

class _PaymentVideoPlayerState extends State<PaymentVideoPlayer>
    with WidgetsBindingObserver {
  double? _dragMs;
  bool _autoPlayed = false;
  bool _foreground = true;

  PaymentVideoController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _c.addListener(_onValue);
    _initializeAfterFrame();
  }

  // After the frame, so a controller that loads synchronously never
  // notifies while this widget is still being built.
  void _initializeAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _c.value.phase == VideoPhase.idle) _c.initialize();
    });
  }

  @override
  void didUpdateWidget(PaymentVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onValue);
      oldWidget.controller.pause();
      _c.addListener(_onValue);
      _autoPlayed = false;
      _initializeAfterFrame();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_visible) _pauseIfPlaying();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      // A load can finish after backgrounding. Consume autoplay as well as
      // pausing existing playback so resume always requires an explicit tap.
      _autoPlayed = true;
      _pauseIfPlaying();
    }
  }

  // Hidden by a route on top or a TickerMode(false) subtree, or by an
  // inactive IndexedStack tab, which keeps tickers running but marks its
  // children invisible.
  bool get _visible =>
      TickerMode.valuesOf(context).enabled && Visibility.of(context);

  void _pauseIfPlaying() {
    final phase = _c.value.phase;
    if (phase == VideoPhase.playing || phase == VideoPhase.buffering) {
      _c.pause();
    }
  }

  void _onValue() {
    if (!mounted) return;
    final ready = _c.value.phase == VideoPhase.ready;
    if (ready &&
        widget.autoPlay &&
        !_autoPlayed &&
        _foreground &&
        !PaymentMotion.of(context).reduced &&
        _visible) {
      _autoPlayed = true;
      _c.play();
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_onValue);
    _pauseIfPlaying();
    super.dispose();
  }

  static String _time(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggle() {
    switch (_c.value.phase) {
      case VideoPhase.playing || VideoPhase.buffering:
        _c.pause();
      case VideoPhase.ended:
        _c.seekTo(Duration.zero).then((_) => _c.play());
      case VideoPhase.ready || VideoPhase.paused:
        _c.play();
      case VideoPhase.idle || VideoPhase.loading || VideoPhase.error:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    final v = _c.value;
    final loaded = switch (v.phase) {
      VideoPhase.ready ||
      VideoPhase.buffering ||
      VideoPhase.playing ||
      VideoPhase.paused ||
      VideoPhase.ended => true,
      _ => false,
    };
    final busy =
        v.phase == VideoPhase.loading || v.phase == VideoPhase.buffering;
    final canControl = loaded;
    final playing =
        v.phase == VideoPhase.playing || v.phase == VideoPhase.buffering;
    final playLabel = v.phase == VideoPhase.ended
        ? l10n.replay
        : playing
        ? l10n.pause
        : l10n.play;
    final playIcon = v.phase == VideoPhase.ended
        ? Icons.replay
        : playing
        ? Icons.pause
        : Icons.play_arrow;
    final maxMs = v.duration.inMilliseconds.toDouble();
    final posMs = (_dragMs ?? v.position.inMilliseconds.toDouble())
        .clamp(0, maxMs > 0 ? maxMs : 0)
        .toDouble();
    final status = switch (v.phase) {
      VideoPhase.loading || VideoPhase.idle => l10n.videoLoading,
      VideoPhase.buffering => l10n.videoBuffering,
      VideoPhase.ended => l10n.videoEnded,
      _ => null,
    };

    Widget picture() {
      if (v.phase == VideoPhase.error) {
        // The explanation sits under the picture with the controls, so it
        // never clips inside a 16:9 frame at large text sizes.
        return const Center(
          child: Icon(
            Icons.videocam_off_outlined,
            size: 32,
            color: Colors.white70,
          ),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          if (loaded)
            ExcludeSemantics(child: _c.buildSurface(context))
          else if (widget.poster != null)
            ExcludeSemantics(child: widget.poster!),
          if (busy)
            const Center(
              child: ExcludeSemantics(
                child: PaymentSpinner(
                  size: PaymentSize.large,
                  color: Colors.white,
                ),
              ),
            )
          else if (canControl && !playing)
            // A large target over the paused picture; hidden while playing
            // so nothing covers the video.
            Center(
              child: PaymentFocusRing(
                // Half the disc: the 36 px icon plus its padding.
                radius: BorderRadius.circular(
                  18 + theme.space(PaymentSpace.block),
                ),
                color: Colors.white,
                child: PaymentPressScale(
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      focusColor: Colors.transparent,
                      onTap: _toggle,
                      child: Padding(
                        padding: EdgeInsets.all(
                          theme.space(PaymentSpace.block),
                        ),
                        child: Icon(
                          playIcon,
                          size: 36,
                          color: Colors.white,
                          semanticLabel: playLabel,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // One radius-8 frame: the picture on top, flat controls under a hairline.
    return Semantics(
      container: true,
      label: widget.title,
      child: Container(
        foregroundDecoration: BoxDecoration(
          borderRadius: theme.borderRadius,
          border: Border.all(color: theme.outline),
        ),
        child: ClipRRect(
          borderRadius: theme.borderRadius,
          child: ColoredBox(
            color: theme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: v.aspectRatio ?? widget.aspectRatio,
                  child: ColoredBox(color: Colors.black, child: picture()),
                ),
                const PaymentDivider(),
                if (v.phase == VideoPhase.error)
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      theme.space(PaymentSpace.block),
                      theme.space(PaymentSpace.block),
                      theme.space(PaymentSpace.block),
                      theme.space(PaymentSpace.inline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.videoErrorTitle, style: type.heading),
                        Text(
                          v.errorMessage ?? l10n.videoErrorMessage,
                          style: type
                              .bodyFor(context)
                              .copyWith(color: theme.textSecondary),
                        ),
                        PaymentLink(label: l10n.retry, onPressed: _c.retry),
                      ],
                    ),
                  )
                else ...[
                  // The 4 px side inset keeps the slider's focus ring inside
                  // the frame's clip.
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      4,
                      theme.space(PaymentSpace.inline),
                      4,
                      0,
                    ),
                    child: Semantics(
                      label: l10n.seek,
                      value: l10n.videoPosition(
                        _time(Duration(milliseconds: posMs.round())),
                        _time(v.duration),
                      ),
                      child: PaymentFocusRing(
                        radius: theme.controlBorderRadius,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: theme.accent,
                            inactiveTrackColor: theme.outline,
                            thumbColor: theme.accent,
                            overlayColor: theme.accent.withValues(alpha: 0.12),
                            trackHeight: 2,
                          ),
                          child: Slider(
                            value: posMs,
                            // The ring marks focus; the halo stays for hover
                            // and drag.
                            overlayColor: WidgetStateProperty.resolveWith(
                              (states) =>
                                  states.contains(WidgetState.focused) &&
                                      !states.contains(WidgetState.dragged) &&
                                      !states.contains(WidgetState.hovered)
                                  ? Colors.transparent
                                  : null,
                            ),
                            max: maxMs > 0 ? maxMs : 1,
                            onChanged: canControl && maxMs > 0
                                ? (ms) => setState(() => _dragMs = ms)
                                : null,
                            onChangeEnd: canControl && maxMs > 0
                                ? (ms) async {
                                    await _c.seekTo(
                                      Duration(milliseconds: ms.round()),
                                    );
                                    if (mounted) setState(() => _dragMs = null);
                                  }
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      theme.space(PaymentSpace.inline),
                      0,
                      theme.space(PaymentSpace.inline),
                      theme.space(PaymentSpace.inline),
                    ),
                    child: Row(
                      children: [
                        PaymentIconButton(
                          icon: playIcon,
                          tooltip: playLabel,
                          onPressed: canControl ? _toggle : null,
                        ),
                        // Loading/buffering/finished are announced; the
                        // running time is not (the slider already speaks it).
                        Expanded(
                          child: Semantics(
                            liveRegion: status != null,
                            excludeSemantics: status == null,
                            child: Text(
                              status ??
                                  '${_time(Duration(milliseconds: posMs.round()))} / ${_time(v.duration)}',
                              style: type.caption.tabular,
                            ),
                          ),
                        ),
                        PaymentIconButton(
                          icon: v.muted
                              ? Icons.volume_off_outlined
                              : Icons.volume_up_outlined,
                          tooltip: v.muted ? l10n.unmute : l10n.mute,
                          onPressed: canControl
                              ? () => _c.setMuted(!v.muted)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
