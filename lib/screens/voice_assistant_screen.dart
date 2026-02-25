import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../l10n/app_strings.dart';
import '../services/gemini_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

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
  late Animation<double> _pulseAnim;

  // AI speaking animation — simulates amplitude-like pulsing
  late AnimationController _aiSpeakController;
  late Animation<double> _aiSpeakAnim;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    _sphereController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // AI speaking: rhythmic breathing animation mimicking speech cadence
    _aiSpeakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _aiSpeakAnim = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _aiSpeakController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) {
        if (!mounted) return;
        // On timeout / no-match errors, auto-restart if user hasn't stopped
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
      },
      onStatus: (status) {
        if (!mounted) return;
        // The platform stopped listening but user didn't ask to stop
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
        setState(() {
          _state = _VoiceState.idle;
          _pulseController.stop();
          _aiSpeakController.stop();
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
    // Small delay to let the platform fully release the recognizer
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
      setState(() {
        _state = _VoiceState.idle;
        _pulseController.stop();
      });
    }
  }

  Future<void> _processVoiceInput() async {
    if (_recognizedText.isEmpty) {
      setState(() {
        _state = _VoiceState.idle;
        _pulseController.stop();
      });
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

    // Start AI speaking animation (rhythmic pulse like user's sound-level)
    _pulseController.repeat(reverse: true);
    _aiSpeakController.repeat(reverse: true);

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
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    String statusText;
    switch (_state) {
      case _VoiceState.idle:
        statusText = s.get('tap_to_speak');
        break;
      case _VoiceState.listening:
        statusText = s.get('listening');
        break;
      case _VoiceState.thinking:
        statusText = s.get('thinking');
        break;
      case _VoiceState.speaking:
        statusText = s.get('speaking');
        break;
    }

    // For AI speaking, use the animated value as a simulated sound level
    final effectiveSoundLevel = _state == _VoiceState.speaking
        ? _aiSpeakAnim.value
        : _soundLevel;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(s.get('voice_assistant')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          _LanguagePill(
            isHindi: _selectedLanguage == 'hi-IN',
            onToggle: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedLanguage = _selectedLanguage == 'hi-IN'
                    ? 'en-US'
                    : 'hi-IN';
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Particle Sphere — centered
            Center(
              child: AnimatedBuilder(
                animation: _state == _VoiceState.speaking
                    ? Listenable.merge([_pulseAnim, _aiSpeakAnim])
                    : _pulseAnim,
                builder: (context, child) {
                  return ScaleTransition(
                    scale: _pulseAnim,
                    child: _ParticleSphere(
                      controller: _sphereController,
                      state: _state,
                      soundLevel: effectiveSoundLevel,
                      isDark: isDark,
                      onTap: () {
                        if (_state == _VoiceState.idle) {
                          _startListening();
                        } else if (_state == _VoiceState.listening) {
                          _stopListening();
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Status text
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  statusText,
                  key: ValueKey(statusText),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recognized text
            if (_recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    '"$_recognizedText"',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // AI Response text
            if (_responseText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      _responseText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

// ─── Language toggle pill ───────────────────────────────────────────────────

class _LanguagePill extends StatelessWidget {
  final bool isHindi;
  final VoidCallback onToggle;
  const _LanguagePill({required this.isHindi, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 16),
            const SizedBox(width: 4),
            Text(
              isHindi ? 'हिंदी' : 'EN',
              style: TextStyle(
                color: primary,
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

// ─── Particle Sphere ────────────────────────────────────────────────────────

class _ParticleSphere extends StatelessWidget {
  final AnimationController controller;
  final _VoiceState state;
  final double soundLevel;
  final bool isDark;
  final VoidCallback onTap;

  const _ParticleSphere({
    required this.controller,
    required this.state,
    required this.soundLevel,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        height: 220,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return CustomPaint(
              size: const Size(220, 220),
              painter: _ParticleSpherePainter(
                time: controller.value,
                state: state,
                soundLevel: soundLevel,
                isDark: isDark,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ParticleSpherePainter extends CustomPainter {
  final double time;
  final _VoiceState state;
  final double soundLevel;
  final bool isDark;

  _ParticleSpherePainter({
    required this.time,
    required this.state,
    required this.soundLevel,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.35;

    // ─── Theme-aware colors ──────────────────────────────────────
    // Light theme: user dots = black, AI dots = orange
    // Dark  theme: user dots = white, AI dots = orange
    Color particleBaseColor;
    Color glowColor;
    switch (state) {
      case _VoiceState.idle:
        particleBaseColor = isDark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.35);
        glowColor = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04);
        break;
      case _VoiceState.listening:
        // User speaking: black (light) / white (dark)
        particleBaseColor = isDark ? Colors.white : Colors.black;
        glowColor = isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.12);
        break;
      case _VoiceState.thinking:
        particleBaseColor = Colors.amber;
        glowColor = Colors.amber.withValues(alpha: 0.15);
        break;
      case _VoiceState.speaking:
        // AI speaking: ORANGE (both themes)
        particleBaseColor = Colors.orange;
        glowColor = Colors.orange.withValues(alpha: 0.2);
        break;
    }

    // ─── Ambient glow ────────────────────────────────────────────
    final glowRadius = baseRadius * (1.3 + soundLevel * 0.3);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [glowColor, glowColor.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // ─── Particle generation ─────────────────────────────────────
    const particleCount = 200;

    // Both listening and speaking get dynamic amplitude distortion
    final amplitude = state == _VoiceState.listening
        ? 0.15 + soundLevel * 0.25
        : state == _VoiceState.speaking
        ? 0.12 +
              soundLevel *
                  0.2 // AI speaking: animated like user
        : state == _VoiceState.thinking
        ? 0.08
        : 0.03;

    for (int i = 0; i < particleCount; i++) {
      // Fibonacci sphere distribution
      final phi = acos(1 - 2 * (i + 0.5) / particleCount);
      final theta = pi * (1 + sqrt(5)) * i + time * 2 * pi;

      // Distort radius based on audio / state
      final distort =
          1.0 +
          amplitude *
              sin(theta * 3 + time * 2 * pi * 2) *
              cos(phi * 2 + time * 2 * pi);
      final r = baseRadius * distort;

      // Project 3D → 2D
      final x3d = r * sin(phi) * cos(theta);
      final y3d = r * sin(phi) * sin(theta);
      final z3d = r * cos(phi);

      // Simple perspective projection
      final scale = 1.0 / (1.0 - z3d / (baseRadius * 4));
      final px = center.dx + x3d * scale;
      final py = center.dy + y3d * scale;

      // Size + alpha based on depth (front = brighter, larger)
      final depth = (z3d / baseRadius + 1) / 2; // 0..1
      final particleSize = 1.5 + depth * 2.5;
      final alpha = (0.15 + depth * 0.85).clamp(0.0, 1.0);

      // Tint particles with the state color
      final pColor = particleBaseColor.withValues(alpha: alpha);

      canvas.drawCircle(
        Offset(px, py),
        particleSize * (1 + soundLevel * 0.3),
        Paint()..color = pColor,
      );
    }

    // ─── Center dot indicator ────────────────────────────────────
    Color centerColor;
    switch (state) {
      case _VoiceState.idle:
        centerColor = isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.2);
        break;
      case _VoiceState.listening:
        centerColor = isDark ? Colors.white : Colors.black;
        break;
      case _VoiceState.thinking:
        centerColor = Colors.amber.withValues(alpha: 0.8);
        break;
      case _VoiceState.speaking:
        centerColor = Colors.orange;
        break;
    }
    canvas.drawCircle(center, 6, Paint()..color = centerColor);
  }

  @override
  bool shouldRepaint(covariant _ParticleSpherePainter old) =>
      old.time != time ||
      old.soundLevel != soundLevel ||
      old.state != state ||
      old.isDark != isDark;
}
