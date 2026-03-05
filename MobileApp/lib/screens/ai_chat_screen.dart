import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/gemini_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../config/environment.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _gemini = GeminiService();
  final ApiService _apiService = ApiService();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _conversationId;

  // Attachment state
  _Attachment? _pendingAttachment;

  @override
  void initState() {
    super.initState();
    _gemini.startNewAiChat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messages.add(
        _ChatMessage(text: S.of(context).get('welcome_message'), isUser: false),
      );
    });
  }

  String _getLanguageCode() {
    try {
      final locale = Localizations.localeOf(context);
      return locale.languageCode;
    } catch (_) {
      return 'en';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingAttachment == null) return;
    if (_isLoading) return;

    HapticFeedback.lightImpact();

    final attachment = _pendingAttachment;
    final displayText = text.isNotEmpty
        ? text
        : 'Attached: ${attachment?.name ?? 'file'}';

    setState(() {
      _messages.add(
        _ChatMessage(
          text: displayText,
          isUser: true,
          attachmentName: attachment?.name,
        ),
      );
      _pendingAttachment = null;
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final prompt = text.isNotEmpty
        ? text
        : 'Please analyze the attached file and provide helpful information about it.';

    String response;
    
    // Check if we should use backend API
    final useBackend = Environment.useBackendApi;
    debugPrint('🔧 Chat: useBackendApi=$useBackend, hasAttachment=${attachment != null}');
    
    if (useBackend) {
      if (attachment != null && attachment.isImage) {
        // Use backend for image analysis
        debugPrint('🔧 Chat: Using backend API for image analysis');
        response = await _sendImageToBackend(prompt, attachment);
      } else if (attachment == null) {
        // Use backend for text-only chat
        debugPrint('🔧 Chat: Using backend API for text chat');
        response = await _sendToBackend(prompt);
      } else {
        // Use Gemini for non-image attachments (PDFs, docs)
        debugPrint('🔧 Chat: Using Gemini for document attachment');
        List<DataPart>? dataParts = [DataPart(attachment.mimeType, attachment.bytes)];
        response = await _gemini.sendAiChatMessage(
          prompt,
          attachments: dataParts,
          language: _getLanguageCode(),
        );
      }
    } else {
      // Use Gemini when backend is disabled
      debugPrint('🔧 Chat: Using Gemini (backend disabled)');
      List<DataPart>? dataParts;
      if (attachment != null) {
        dataParts = [DataPart(attachment.mimeType, attachment.bytes)];
      }
      response = await _gemini.sendAiChatMessage(
        prompt,
        attachments: dataParts,
        language: _getLanguageCode(),
      );
    }

    HapticFeedback.selectionClick();
    setState(() {
      _messages.add(_ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  /// Send message to FastAPI backend (uses Amazon Nova)
  Future<String> _sendToBackend(String message) async {
    try {
      final authProvider = context.read<AuthProvider>();
      
      debugPrint('🔧 Chat: isAuthenticated=${authProvider.isAuthenticated}');
      debugPrint('🔧 Chat: accessToken present=${authProvider.accessToken != null}');
      
      if (!authProvider.isAuthenticated) {
        // Fallback to Gemini if not authenticated
        debugPrint('🔧 Chat: Not authenticated, falling back to Gemini');
        return await _gemini.sendAiChatMessage(
          message,
          language: _getLanguageCode(),
        );
      }

      debugPrint('🔧 Chat: Sending to backend API...');
      final result = await _apiService.sendChatMessage(
        authToken: authProvider.accessToken!,
        message: message,
        language: _getLanguageCode(),
        conversationId: _conversationId,
      );

      debugPrint('🔧 Chat: Backend response received');
      _conversationId = result['conversation_id'] as String?;
      return result['response'] as String? ?? 'No response received';
    } catch (e) {
      debugPrint('🔧 Chat: Backend error: $e');
      debugPrint('🔧 Chat: Falling back to Gemini due to error');
      // Fallback to Gemini on error
      return await _gemini.sendAiChatMessage(
        message,
        language: _getLanguageCode(),
      );
    }
  }

  /// Send image to FastAPI backend for analysis
  Future<String> _sendImageToBackend(String message, _Attachment attachment) async {
    try {
      final authProvider = context.read<AuthProvider>();
      
      if (!authProvider.isAuthenticated) {
        debugPrint('🔧 Chat: Not authenticated, falling back to Gemini for image');
        return await _gemini.sendAiChatMessage(
          message,
          attachments: [DataPart(attachment.mimeType, attachment.bytes)],
          language: _getLanguageCode(),
        );
      }

      debugPrint('🔧 Chat: Sending image to backend API...');
      final imageBase64 = base64Encode(attachment.bytes);
      
      final result = await _apiService.sendChatWithImage(
        authToken: authProvider.accessToken!,
        message: message,
        imageBase64: imageBase64,
        imageType: attachment.mimeType,
        language: _getLanguageCode(),
      );

      debugPrint('🔧 Chat: Backend image analysis received');
      _conversationId = result['conversation_id'] as String?;
      return result['response'] as String? ?? 'No response received';
    } catch (e) {
      debugPrint('🔧 Chat: Backend image error: $e');
      debugPrint('🔧 Chat: Falling back to Gemini for image analysis');
      // Fallback to Gemini on error
      return await _gemini.sendAiChatMessage(
        message,
        attachments: [DataPart(attachment.mimeType, attachment.bytes)],
        language: _getLanguageCode(),
      );
    }
  }

  Future<void> _pickImage() async {
    await _ensurePermission();
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final ext = image.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        setState(() {
          _pendingAttachment = _Attachment(
            name: image.name,
            mimeType: mime,
            bytes: bytes,
            isImage: true,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    await _ensurePermission();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'csv'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _pendingAttachment = _Attachment(
              name: file.name,
              mimeType: _getMimeType(file.extension ?? ''),
              bytes: file.bytes!,
              isImage: false,
            );
          });
        }
      }
    } catch (_) {}
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _ensurePermission() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('file_permission_asked') ?? false;
    if (!asked) {
      // First time: ask for storage permission
      if (Platform.isAndroid) {
        await Permission.photos.request();
        await Permission.camera.request();
      }
      await prefs.setBool('file_permission_asked', true);
    }
  }

  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(s.get('take_photo')),
                  subtitle: Text(
                    'JPG, PNG',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.attach_file_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  title: Text(s.get('choose_file')),
                  subtitle: Text(
                    'PDF, DOC, TXT, CSV',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('ai_chat')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New chat',
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _messages.clear();
                _gemini.startNewAiChat();
                _messages.add(
                  _ChatMessage(
                    text: s.get('new_chat_started_message'),
                    isUser: false,
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _TypingIndicator(color: primary);
                }
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),

          // Pending attachment preview
          if (_pendingAttachment != null) _buildAttachmentPreview(isDark),

          // Input bar
          _buildInputBar(context, isDark, s, primary),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(bool isDark) {
    final att = _pendingAttachment!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            att.isImage ? Icons.image_rounded : Icons.description_rounded,
            color: att.isImage ? Colors.blue : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              att.name,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _pendingAttachment = null),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    bool isDark,
    AppStrings s,
    Color primary,
  ) {
    final barBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final topBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: topBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button
            GestureDetector(
              onTap: _showAttachmentSheet,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color: primary,
                  size: 26,
                ),
              ),
            ),

            // Text field
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: s.get('type_message'),
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
                    borderSide: BorderSide(color: primary),
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

            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                decoration: BoxDecoration(
                  color: primary,
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
          ],
        ),
      ),
    );
  }
}

// ─── Data classes ────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? attachmentName;
  _ChatMessage({required this.text, required this.isUser, this.attachmentName});
}

class _Attachment {
  final String name;
  final String mimeType;
  final Uint8List bytes;
  final bool isImage;
  _Attachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
    required this.isImage,
  });
}

// ─── Chat Bubble ─────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final aiBubbleBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final aiBorderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final aiTextColor = isDark ? Colors.white : Colors.black87;

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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attachment badge
            if (message.attachmentName != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        message.attachmentName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Message text
            message.isUser
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
                      p: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: aiTextColor,
                      ),
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
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Apple iMessage-style Typing Indicator ───────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _dotControllers;
  late final List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();

    // Three controllers, staggered start — Apple iMessage cadence
    _dotControllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _dotAnimations = _dotControllers.map((c) {
      return Tween<double>(
        begin: 0,
        end: -8,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();

    // Start each dot with a staggered delay
    _startAnimations();
  }

  void _startAnimations() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _dotControllers[i].forward();
        await Future.delayed(const Duration(milliseconds: 160));
      }
      // Wait for last dot to finish, then reverse all
      await Future.delayed(const Duration(milliseconds: 200));
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _dotControllers[i].reverse();
        await Future.delayed(const Duration(milliseconds: 120));
      }
      // Brief pause before next cycle
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    for (final c in _dotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _dotAnimations[i],
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.translate(
                    offset: Offset(0, _dotAnimations[i].value),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
