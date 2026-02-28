import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../l10n/app_strings.dart';
import '../services/gemini_service.dart';
import '../providers/user_profile_provider.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final UserProfileProvider profileProvider;
  const VoiceAssistantScreen({super.key, required this.profileProvider});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

enum _VoiceState { idle, listening, thinking, speaking }

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GeminiService _gemini = GeminiService();

  _VoiceState _state = _VoiceState.idle;
  String _recognizedText = '';
  String _responseText = '';
  String _selectedLanguage = 'en-US';
  bool _speechAvailable = false;
  double _soundLevel = 0.0;

  /// Tracks whether the user manually tapped stop.
  /// When false, premature stops trigger an automatic restart.
  bool _userStoppedManually = false;

  /// Whether we are currently in a listening session (may span
  /// multiple platform listen/restart cycles).
  bool _isInListeningSession = false;

  late AnimationController _sphereController;
  late AnimationController _pulseController;
  final Stopwatch _sphereStopwatch = Stopwatch();

  // AI speaking animation — rhythmic breathing pulse
  late AnimationController _aiSpeakController;
  late Animation<double> _aiSpeakAnim;

  // Smooth intensity transition (idle ↔ active)
  late AnimationController _intensityController;
  late Animation<double> _intensityAnim;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    // Continuous ticker — drives sphere repaint every frame
    _sphereController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    // Stopwatch provides true monotonic elapsed time (no accumulation bugs)
    _sphereStopwatch.start();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // AI speaking: rhythmic breathing animation mimicking speech cadence
    _aiSpeakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _aiSpeakAnim = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _aiSpeakController, curve: Curves.easeInOut),
    );

    // Smooth transition between idle (0) and active (1) states
    // Apple uses long, decelerating ease-out for “settling” animations
    _intensityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _intensityAnim = CurvedAnimation(
      parent: _intensityController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) {
        if (!mounted) return;
        final recoverable =
            e.errorMsg == 'error_speech_timeout' ||
            e.errorMsg == 'error_no_match';
        if (recoverable && _isInListeningSession && !_userStoppedManually) {
          _restartListening();
          return;
        }
        setState(() {
          _state = _VoiceState.idle;
          _isInListeningSession = false;
          _pulseController.stop();
          _aiSpeakController.stop();
        });
        _intensityController.animateTo(0);
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening' &&
            _isInListeningSession &&
            !_userStoppedManually &&
            _state == _VoiceState.listening) {
          _restartListening();
        }
      },
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setSharedInstance(true);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) {
        // Apple-style: fade sound level to zero first, then transition state
        setState(() {
          _soundLevel = 0;
          _aiSpeakController.stop();
        });
        // Gracefully ramp intensity down (900ms easeOutCubic)
        _intensityController.animateTo(0).then((_) {
          if (mounted) {
            setState(() {
              _state = _VoiceState.idle;
              _pulseController.stop();
            });
          }
        });
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showError('Speech recognition not available');
      return;
    }

    HapticFeedback.heavyImpact();
    _userStoppedManually = false;
    _isInListeningSession = true;
    setState(() {
      _state = _VoiceState.listening;
      _recognizedText = '';
      _responseText = '';
      _soundLevel = 0;
    });
    _pulseController.repeat(reverse: true);
    // Smoothly ramp up sphere intensity
    _intensityController.animateTo(1.0);

    await _beginListenCycle();
  }

  /// Core listen call extracted so it can be invoked on first start
  /// and on every automatic restart.
  Future<void> _beginListenCycle() async {
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
        if (result.finalResult && _recognizedText.isNotEmpty) {
          _isInListeningSession = false;
          _processVoiceInput();
        }
      },
      onSoundLevelChange: (level) {
        setState(() {
          _soundLevel = (level + 10).clamp(0, 20) / 20;
        });
      },
      localeId: _selectedLanguage,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 5),
    );
  }

  /// Restarts the speech recognizer seamlessly when the platform
  /// times out but the user hasn't stopped manually.
  void _restartListening() {
    if (!_isInListeningSession || _userStoppedManually || !mounted) return;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_isInListeningSession || _userStoppedManually || !mounted) return;
      _beginListenCycle();
    });
  }

  Future<void> _stopListening() async {
    _userStoppedManually = true;
    _isInListeningSession = false;
    await _speech.stop();
    if (_recognizedText.isNotEmpty) {
      _processVoiceInput();
    } else {
      // Apple-style: gracefully fade out, then set idle
      setState(() => _soundLevel = 0);
      _intensityController.animateTo(0).then((_) {
        if (mounted) {
          setState(() {
            _state = _VoiceState.idle;
            _pulseController.stop();
          });
        }
      });
    }
  }

  Future<void> _processVoiceInput() async {
    if (_recognizedText.isEmpty) {
      setState(() {
        _state = _VoiceState.idle;
        _pulseController.stop();
      });
      _intensityController.animateTo(0);
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _state = _VoiceState.thinking);

    final lang = _selectedLanguage.startsWith('hi') ? 'hi' : 'en';
    final response = await _gemini.sendVoiceMessage(
      _recognizedText,
      language: lang,
    );

    if (!mounted) return;
    setState(() {
      _responseText = response;
      _state = _VoiceState.speaking;
    });

    // Start AI speaking animation (rhythmic pulse)
    _pulseController.repeat(reverse: true);
    _aiSpeakController.repeat(reverse: true);
    // Keep intensity high during speaking
    _intensityController.animateTo(1.0);

    final ttsLang = _selectedLanguage.startsWith('hi') ? 'hi-IN' : 'en-US';
    await _tts.setLanguage(ttsLang);
    await _tts.speak(response);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _sphereController.dispose();
    _pulseController.dispose();
    _aiSpeakController.dispose();
    _intensityController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    // ── Theme-adaptive colors ──────────────────────────────────
    final bgColor = isDark ? Colors.black : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.5);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    String statusText;
    Color statusDotColor;
    switch (_state) {
      case _VoiceState.idle:
        statusText = s.get('tap_to_speak');
        statusDotColor = isDark
            ? const Color(0xFFCCCCCC)
            : const Color(0xFF666666);
        break;
      case _VoiceState.listening:
        statusText = s.get('listening');
        statusDotColor = const Color(0xFFE8A838);
        break;
      case _VoiceState.thinking:
        statusText = s.get('thinking');
        statusDotColor = const Color(0xFFDDA030);
        break;
      case _VoiceState.speaking:
        statusText = s.get('speaking');
        statusDotColor = const Color(0xFFE8A838);
        break;
    }

    // For AI speaking, use the animated value as a simulated sound level
    final effectiveSoundLevel = _state == _VoiceState.speaking
        ? _aiSpeakAnim.value
        : _soundLevel;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: bgColor,
          ),
      child: Scaffold(
        backgroundColor: bgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            s.get('voice_assistant'),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: textColor.withValues(alpha: 0.7),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          actions: [
            _LanguagePill(
              isHindi: _selectedLanguage == 'hi-IN',
              isDark: isDark,
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedLanguage = _selectedLanguage == 'hi-IN'
                      ? 'en-US'
                      : 'hi-IN';
                });
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Particle sphere ─────────────────────────────────
              Center(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _sphereController,
                      _aiSpeakAnim,
                      _intensityAnim,
                    ]),
                    builder: (context, _) {
                      return _ParticleSphere(
                        // Stopwatch gives true monotonic seconds
                        elapsedSeconds:
                            _sphereStopwatch.elapsedMicroseconds / 1e6,
                        state: _state,
                        soundLevel: effectiveSoundLevel,
                        speakingLevel: _state == _VoiceState.speaking
                            ? _aiSpeakAnim.value
                            : 0.0,
                        intensity: _intensityAnim.value,
                        isDark: isDark,
                        onTap: () {
                          if (_state == _VoiceState.idle) {
                            _startListening();
                          } else if (_state == _VoiceState.listening) {
                            _stopListening();
                          }
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Status indicator row ────────────────────────────
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Row(
                    key: ValueKey(statusText),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusDotColor,
                          boxShadow: [
                            BoxShadow(
                              color: statusDotColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Recognized text ─────────────────────────────────
              if (_recognizedText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        '"$_recognizedText"',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          letterSpacing: -0.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              // ── AI response ─────────────────────────────────────
              if (_responseText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE8A838,
                      ).withValues(alpha: isDark ? 0.06 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(
                          0xFFE8A838,
                        ).withValues(alpha: isDark ? 0.08 : 0.12),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        _responseText,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 14,
                          height: 1.6,
                          letterSpacing: -0.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Language toggle pill ───────────────────────────────────────────────────

class _LanguagePill extends StatelessWidget {
  final bool isHindi;
  final bool isDark;
  final VoidCallback onToggle;
  const _LanguagePill({
    required this.isHindi,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = isDark ? Colors.white70 : Colors.black54;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 16, color: fgColor),
            const SizedBox(width: 4),
            Text(
              isHindi ? 'हिंदी' : 'EN',
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Perplexity-style Particle Sphere ───────────────────────────────────────

class _ParticleSphere extends StatelessWidget {
  final double elapsedSeconds;
  final _VoiceState state;
  final double soundLevel;
  final double speakingLevel;
  final double intensity;
  final bool isDark;
  final VoidCallback onTap;

  const _ParticleSphere({
    required this.elapsedSeconds,
    required this.state,
    required this.soundLevel,
    required this.speakingLevel,
    required this.intensity,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 280,
        height: 280,
        child: CustomPaint(
          size: const Size(280, 280),
          painter: _ParticleSpherePainter(
            time: elapsedSeconds,
            state: state,
            soundLevel: soundLevel,
            speakingLevel: speakingLevel,
            intensity: intensity,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

// ─── Perplexity-style painter with Simplex noise ────────────────────────────

class _ParticleSpherePainter extends CustomPainter {
  final double time;
  final _VoiceState state;
  final double soundLevel;
  final double speakingLevel;
  final double intensity;
  final bool isDark;

  static final _SimplexNoise _noise = _SimplexNoise(42);

  static final List<double> _scatterSeeds = List.generate(
    700,
    (i) => _SimplexNoise(i * 7 + 13).noise3D(i * 0.1, i * 0.2, i * 0.3),
  );

  _ParticleSpherePainter({
    required this.time,
    required this.state,
    required this.soundLevel,
    required this.speakingLevel,
    required this.intensity,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.34;

    // ─── Theme-adaptive + state-aware dot color ──────────────────
    Color dotColor;
    double ambientAlpha;
    final bool isActive = state != _VoiceState.idle;

    if (!isActive) {
      dotColor = isDark ? const Color(0xFFBBBBBB) : const Color(0xFF555555);
      ambientAlpha = isDark ? 0.03 : 0.02;
    } else if (state == _VoiceState.thinking) {
      dotColor = const Color(0xFFDDA030);
      ambientAlpha = 0.06;
    } else {
      dotColor = const Color(0xFFE8A838);
      ambientAlpha = 0.05;
    }

    // ─── Subtle ambient glow ──────────────────────────────────────
    final glowRadius = baseRadius * (1.2 + intensity * 0.2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          dotColor.withValues(alpha: ambientAlpha * (0.5 + intensity * 0.5)),
          dotColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // ─── Particle system ─────────────────────────────────────────
    const particleCount = 700;
    // time is now monotonic seconds — never wraps, perfectly smooth
    final t = time;

    // Smoothly interpolated noise via intensity (0→1)
    const idleNoise = 0.02;
    final activeNoise = state == _VoiceState.listening
        ? 0.08 + soundLevel * 0.15
        : state == _VoiceState.speaking
        ? 0.06 + speakingLevel * 0.14
        : state == _VoiceState.thinking
        ? 0.06
        : 0.02;
    final noiseAmp = idleNoise + (activeNoise - idleNoise) * intensity;

    // Smoothly interpolated edge scatter
    const idleScatter = 0.03;
    final activeScatter = state == _VoiceState.listening
        ? 0.10 + soundLevel * 0.18
        : state == _VoiceState.speaking
        ? 0.08 + speakingLevel * 0.12
        : state == _VoiceState.thinking
        ? 0.06
        : 0.03;
    final scatterAmp = idleScatter + (activeScatter - idleScatter) * intensity;

    // Slow rotation: ~1 full turn per 40s in idle
    final rotAngle = t * 0.15 * (state == _VoiceState.thinking ? 1.8 : 1.0);

    // Speaking breathing — visible gentle rhythmic radius modulation
    final breathe = state == _VoiceState.speaking
        ? 1.0 + speakingLevel * 0.05 * intensity
        : 1.0;

    final dotPaint = Paint();

    for (int i = 0; i < particleCount; i++) {
      final phi = acos(1 - 2 * (i + 0.5) / particleCount);
      final theta = pi * (1 + sqrt(5)) * i + rotAngle;

      final nx = sin(phi) * cos(theta);
      final ny = sin(phi) * sin(theta);
      final nz = cos(phi);

      // Low-frequency noise for silky smooth motion
      final noiseVal = _noise.noise3D(
        nx * 1.2 + t * 0.06,
        ny * 1.2 + t * 0.05,
        nz * 1.2 + t * 0.04,
      );

      final scatterSeed = _scatterSeeds[i];
      final isEdge = scatterSeed.abs() > 0.3;
      final scatter = isEdge
          ? scatterSeed * scatterAmp * (1.0 + 0.4 * sin(t * 0.2 + i * 0.05))
          : 0.0;

      final distort = breathe + noiseAmp * noiseVal + scatter;
      final r = baseRadius * distort;

      final x3d = r * nx;
      final y3d = r * ny;
      final z3d = r * nz;

      final perspective = 1.0 / (1.0 - z3d / (baseRadius * 5.0));
      final px = center.dx + x3d * perspective;
      final py = center.dy + y3d * perspective;

      final depth = ((z3d / baseRadius + 1) / 2).clamp(0.0, 1.0);
      final dotSize = (0.6 + depth * 1.4) * (1 + soundLevel * 0.1);
      final alpha = (0.08 + depth * 0.92).clamp(0.0, 1.0);

      dotPaint.color = dotColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), dotSize, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleSpherePainter old) =>
      old.time != time ||
      old.soundLevel != soundLevel ||
      old.speakingLevel != speakingLevel ||
      old.intensity != intensity ||
      old.state != state ||
      old.isDark != isDark;
}

// ─── Lightweight 3D Simplex Noise (pure Dart, no dependencies) ──────────────

class _SimplexNoise {
  late final Int32List _perm;

  static const double _f3 = 1.0 / 3.0;
  static const double _g3 = 1.0 / 6.0;

  static const List<List<int>> _grad3 = [
    [1, 1, 0],
    [-1, 1, 0],
    [1, -1, 0],
    [-1, -1, 0],
    [1, 0, 1],
    [-1, 0, 1],
    [1, 0, -1],
    [-1, 0, -1],
    [0, 1, 1],
    [0, -1, 1],
    [0, 1, -1],
    [0, -1, -1],
  ];

  _SimplexNoise(int seed) {
    final rng = Random(seed);
    final p = List<int>.generate(256, (i) => i)..shuffle(rng);
    _perm = Int32List(512);
    for (int i = 0; i < 512; i++) {
      _perm[i] = p[i & 255];
    }
  }

  double noise3D(double xin, double yin, double zin) {
    final s = (xin + yin + zin) * _f3;
    final i = (xin + s).floor();
    final j = (yin + s).floor();
    final k = (zin + s).floor();

    final t = (i + j + k) * _g3;
    final x0 = xin - (i - t);
    final y0 = yin - (j - t);
    final z0 = zin - (k - t);

    int i1, j1, k1, i2, j2, k2;
    if (x0 >= y0) {
      if (y0 >= z0) {
        i1 = 1;
        j1 = 0;
        k1 = 0;
        i2 = 1;
        j2 = 1;
        k2 = 0;
      } else if (x0 >= z0) {
        i1 = 1;
        j1 = 0;
        k1 = 0;
        i2 = 1;
        j2 = 0;
        k2 = 1;
      } else {
        i1 = 0;
        j1 = 0;
        k1 = 1;
        i2 = 1;
        j2 = 0;
        k2 = 1;
      }
    } else {
      if (y0 < z0) {
        i1 = 0;
        j1 = 0;
        k1 = 1;
        i2 = 0;
        j2 = 1;
        k2 = 1;
      } else if (x0 < z0) {
        i1 = 0;
        j1 = 1;
        k1 = 0;
        i2 = 0;
        j2 = 1;
        k2 = 1;
      } else {
        i1 = 0;
        j1 = 1;
        k1 = 0;
        i2 = 1;
        j2 = 1;
        k2 = 0;
      }
    }

    final x1 = x0 - i1 + _g3;
    final y1 = y0 - j1 + _g3;
    final z1 = z0 - k1 + _g3;
    final x2 = x0 - i2 + 2.0 * _g3;
    final y2 = y0 - j2 + 2.0 * _g3;
    final z2 = z0 - k2 + 2.0 * _g3;
    final x3 = x0 - 1.0 + 3.0 * _g3;
    final y3 = y0 - 1.0 + 3.0 * _g3;
    final z3 = z0 - 1.0 + 3.0 * _g3;

    final ii = i & 255;
    final jj = j & 255;
    final kk = k & 255;

    double n0 = 0, n1 = 0, n2 = 0, n3 = 0;

    var t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0;
    if (t0 > 0) {
      t0 *= t0;
      final gi0 = _perm[ii + _perm[jj + _perm[kk]]] % 12;
      n0 = t0 * t0 * _dot3(_grad3[gi0], x0, y0, z0);
    }

    var t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1;
    if (t1 > 0) {
      t1 *= t1;
      final gi1 = _perm[ii + i1 + _perm[jj + j1 + _perm[kk + k1]]] % 12;
      n1 = t1 * t1 * _dot3(_grad3[gi1], x1, y1, z1);
    }

    var t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2;
    if (t2 > 0) {
      t2 *= t2;
      final gi2 = _perm[ii + i2 + _perm[jj + j2 + _perm[kk + k2]]] % 12;
      n2 = t2 * t2 * _dot3(_grad3[gi2], x2, y2, z2);
    }

    var t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3;
    if (t3 > 0) {
      t3 *= t3;
      final gi3 = _perm[ii + 1 + _perm[jj + 1 + _perm[kk + 1]]] % 12;
      n3 = t3 * t3 * _dot3(_grad3[gi3], x3, y3, z3);
    }

    return 32.0 * (n0 + n1 + n2 + n3);
  }

  static double _dot3(List<int> g, double x, double y, double z) {
    return g[0] * x + g[1] * y + g[2] * z;
  }
}
