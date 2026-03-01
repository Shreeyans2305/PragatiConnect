import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../constants.dart';
import '../widgets/app_drawer.dart';
import '../services/gemini_service.dart';

class SchemeAssistantScreen extends StatefulWidget {
  const SchemeAssistantScreen({super.key});

  @override
  State<SchemeAssistantScreen> createState() => _SchemeAssistantScreenState();
}

class _SchemeAssistantScreenState extends State<SchemeAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _gemini = GeminiService();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gemini.startNewSchemeChat();
    _messages.add(
      _ChatMessage(
        text:
            'Namaste! 🙏 I\'m your Scheme Assistant. I can help you discover government welfare schemes you may be eligible for.\n\nTell me about your occupation and location, or ask about a specific scheme like PM-KISAN!',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final response = await _gemini.sendSchemeMessage(text);

    HapticFeedback.selectionClick();
    setState(() {
      _messages.add(_ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Assistant'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New conversation',
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _messages.clear();
                _gemini.startNewSchemeChat();
                _messages.add(
                  _ChatMessage(
                    text: 'Namaste! 🙏 How can I help you today?',
                    isUser: false,
                  ),
                );
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 1),
      body: Column(
        children: [
          // API key banner
          if (!_gemini.isConfigured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.tertiary.withValues(alpha: 0.2),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Using demo mode. Add your Gemini API key for full AI responses.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingIndicator();
                }
                return _AnimatedChatBubble(
                  message: _messages[index],
                  index: index,
                );
              },
            ),
          ),

          // Input bar
          _buildInputBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark) {
    final barBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final topBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: topBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Ask about government schemes...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(onTap: _sendMessage),
          ],
        ),
      ),
    );
  }
}

// ─── Data class ──────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

// ─── Animated Chat Bubble (slides in from side) ─────────────────────────────

class _AnimatedChatBubble extends StatefulWidget {
  final _ChatMessage message;
  final int index;

  const _AnimatedChatBubble({required this.message, required this.index});

  @override
  State<_AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<_AnimatedChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    final startX = widget.message.isUser ? 0.15 : -0.15;
    _slideAnim = Tween<Offset>(
      begin: Offset(startX, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _ChatBubbleContent(message: widget.message),
      ),
    );
  }
}

// ─── Chat Bubble Content (dark-mode aware) ───────────────────────────────────

class _ChatBubbleContent extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubbleContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final aiBubbleBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final aiBorderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final aiTextColor = isDark ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isUser ? primary : aiBubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 18),
          ),
          border: message.isUser ? null : Border.all(color: aiBorderClr),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: message.isUser
            ? Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              )
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 15, height: 1.5, color: aiTextColor),
                  h1: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: aiTextColor,
                  ),
                  h2: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: aiTextColor,
                  ),
                  h3: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: aiTextColor,
                  ),
                  listBullet: TextStyle(fontSize: 15, color: aiTextColor),
                  blockquote: TextStyle(
                    fontSize: 14,
                    color: primary,
                    backgroundColor: primary.withValues(alpha: 0.1),
                  ),
                  code: TextStyle(
                    fontSize: 13,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade100,
                    color: aiTextColor,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Send Button with press animation ────────────────────────────────────────

class _SendButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SendButton({required this.onTap});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.animateTo(0.9),
      onTapUp: (_) {
        _ctrl.animateTo(1.0, curve: Curves.elasticOut);
        widget.onTap();
      },
      onTapCancel: () => _ctrl.animateTo(1.0),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─── Typing Indicator ────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final dotColor = Theme.of(context).colorScheme.secondary;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderClr),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.2;
                final t = (_controller.value - delay).clamp(0.0, 1.0);
                final scale = 0.5 + 0.5 * (1 - (2 * t - 1).abs());
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor.withValues(alpha: 0.6 + 0.4 * scale),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
