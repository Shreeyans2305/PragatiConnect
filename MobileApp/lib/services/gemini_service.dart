import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/environment.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // API key loaded from environment
  String get _apiKey => Environment.geminiApiKey;

  GenerativeModel? _schemeModel;
  GenerativeModel? _businessModel;
  GenerativeModel? _chatModel;
  GenerativeModel? _schemesListModel;
  ChatSession? _schemeChat;
  ChatSession? _aiChat;

  bool get isConfigured => Environment.isGeminiConfigured;

  // ─── Scheme Assistant Model ──────────────────────────────────────────────
  GenerativeModel get schemeModel {
    _schemeModel ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        '''You are Pragati Connect's Scheme Assistant — an expert on Indian government welfare schemes for informal workers.

Your role:
- Help users discover government schemes they may be eligible for (PM-KISAN, PMAY, Vishwakarma Yojana, etc.)
- Explain eligibility criteria, benefits, application processes, and deadlines in simple language
- Be empathetic and supportive, understanding users may have low literacy levels
- Support questions in Hindi and English
- Always provide actionable next steps
- If unsure about specific details, say so honestly and suggest where to find accurate info

Keep responses concise, friendly, and easy to understand. Use bullet points for lists.''',
      ),
    );
    return _schemeModel!;
  }

  // ─── Business Profile Model ──────────────────────────────────────────────
  GenerativeModel get businessModel {
    _businessModel ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        '''You are a business profile and marketing content generator for Indian micro-entrepreneurs and informal workers.

Your role:
- Generate professional business descriptions and marketing content
- Create compelling taglines and service descriptions
- Suggest pricing strategies and business tips
- Write content in clear, professional language suitable for business cards, social media, and flyers
- Be encouraging and supportive of small businesses

Format your response with clear sections using markdown headers and bullet points.''',
      ),
    );
    return _businessModel!;
  }

  // ─── General AI Chat Model ──────────────────────────────────────────────
  GenerativeModel get chatModel {
    _chatModel ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        '''You are Pragati Connect's AI Assistant — a helpful, friendly assistant for India's informal workforce.

Your role:
- Answer general questions about livelihoods, government services, digital tools, and daily life
- Help with writing, calculations, and understanding documents
- Be warm, empathetic, and use simple language
- Support both Hindi and English
- When users attach images or files, describe what you see and help accordingly
- Format responses with markdown for readability

Keep responses concise and actionable.''',
      ),
    );
    return _chatModel!;
  }

  // ─── Schemes List Model ──────────────────────────────────────────────────
  GenerativeModel get schemesListModel {
    _schemesListModel ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        '''You are an expert on Indian government welfare schemes. When asked, provide a list of currently active government schemes in India for informal workers, farmers, artisans, and small businesses.

IMPORTANT: Respond ONLY with valid JSON. No markdown, no code fences, no extra text.

The JSON must be an array of objects with these exact fields:
- "name": scheme name (string)
- "description": 1-2 sentence description (string)
- "category": one of "Agriculture", "Housing", "Employment", "Health", "Education", "Business", "Social Security" (string)
- "ministry": implementing ministry name (string)
- "benefitAmount": benefit amount or description (string)''',
      ),
    );
    return _schemesListModel!;
  }

  // ─── Chat Methods ────────────────────────────────────────────────────────

  void startNewSchemeChat() {
    _schemeChat = schemeModel.startChat();
  }

  void startNewAiChat() {
    _aiChat = chatModel.startChat();
  }

  Future<String> sendSchemeMessage(String message) async {
    if (!isConfigured) return _getMockSchemeResponse(message);
    try {
      _schemeChat ??= schemeModel.startChat();
      final response = await _schemeChat!.sendMessage(Content.text(message));
      return response.text ??
          'I could not generate a response. Please try again.';
    } catch (e) {
      return 'Sorry, I encountered an error: ${e.toString().split('\n').first}. Please try again.';
    }
  }

  Future<String> sendAiChatMessage(
    String message, {
    List<DataPart>? attachments,
    String language = 'en',
  }) async {
    if (!isConfigured) return _getMockChatResponse(message);
    try {
      _aiChat ??= chatModel.startChat();
      final langHint = language == 'hi'
          ? '\n\n[IMPORTANT: Respond entirely in Hindi (Devanagari script). All text must be in Hindi.]'
          : '';
      final parts = <Part>[TextPart('$message$langHint')];
      if (attachments != null) {
        parts.addAll(attachments);
      }
      final response = await _aiChat!.sendMessage(Content.multi(parts));
      return response.text ??
          'I could not generate a response. Please try again.';
    } catch (e) {
      return 'Sorry, I encountered an error: ${e.toString().split('\n').first}. Please try again.';
    }
  }

  Future<String> sendVoiceMessage(
    String spokenText, {
    String language = 'en',
  }) async {
    if (!isConfigured) return _getMockVoiceResponse(spokenText);
    try {
      final langInstruction = language == 'hi'
          ? 'Reply ONLY in Hindi (Devanagari script). Do NOT use English.'
          : 'Reply in English.';
      final response = await chatModel.generateContent([
        Content.text(
          'The user spoke the following via voice. $langInstruction Keep your response brief (2-3 sentences max) as it will be read aloud via TTS:\n\n"$spokenText"',
        ),
      ]);
      return response.text ?? 'I could not understand. Please try again.';
    } catch (e) {
      return 'Sorry, there was an error. Please try again.';
    }
  }

  Future<String> generateBusinessProfile({
    required String businessName,
    required String businessType,
    required String location,
    required String description,
    String language = 'en',
  }) async {
    final languageInstructions = _getLanguageInstructions(language);
    
    final prompt =
        '''Generate a professional business profile and marketing content for:

**Business Name:** $businessName
**Business Type:** $businessType
**Location:** $location
**Description:** $description

$languageInstructions

CRITICAL RULES:
- Use ONLY this location: "$location"
- Never invent or substitute any other city/state
- If location is empty, do not mention any specific city/state
- Keep every heading and sentence in the requested language only

Please provide:
1. A professional business description (2-3 paragraphs)
2. A catchy tagline
3. Key services/products list
4. A short social media bio
5. 2-3 marketing tips specific to this business type''';

    if (!isConfigured) {
      return _getMockBusinessResponse(
        businessName,
        businessType,
        location: location,
        language: language,
      );
    }

    try {
      final response = await businessModel.generateContent([
        Content.text(prompt),
      ]);
      return response.text ?? 'Could not generate profile. Please try again.';
    } catch (e) {
      return 'Sorry, I encountered an error: ${e.toString().split('\n').first}. Please try again.';
    }
  }

  // ─── Government Schemes Fetching ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchGovernmentSchemes({
    String language = 'en',
  }) async {
    if (!isConfigured) return _getMockSchemes(language: language);
    try {
      final langInstruction = language == 'hi'
          ? 'Write ALL scheme names and descriptions in Hindi (Devanagari script). Keep category values in English for internal use.'
          : 'Write in English.';
      final response = await schemesListModel.generateContent([
        Content.text(
          'List 15 currently active Indian government welfare schemes for informal workers, farmers, artisans, women, and small businesses. Include major schemes like PM-KISAN, PMAY, PM Vishwakarma, MGNREGA, Jan Dhan, Ayushman Bharat, etc. $langInstruction Return ONLY valid JSON array.',
        ),
      ]);
      final text = response.text ?? '[]';
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> parsed = jsonDecode(cleaned);
      return parsed.cast<Map<String, dynamic>>();
    } catch (e) {
      return _getMockSchemes(language: language);
    }
  }

  Future<String> fetchSchemeDetails(
    String schemeName, {
    String language = 'en',
  }) async {
    if (!isConfigured) return _getMockSchemeDetails(schemeName);
    try {
      final langInstruction = language == 'hi'
          ? 'Write the ENTIRE response in Hindi (Devanagari script). All headings, descriptions, and details must be in Hindi.'
          : 'Write in English.';
      final response = await chatModel.generateContent([
        Content.text(
          '''Provide a comprehensive, well-formatted guide about the "$schemeName" government scheme in India. $langInstruction Include:

## Overview
Brief introduction

## Key Benefits
- List of benefits with amounts

## Eligibility Criteria
- Who can apply

## How to Apply
Step-by-step process

## Documents Required
- List of documents

## Important Links & Contact
- Official website, helpline numbers

## Recent Updates
- Any recent changes or updates

Use markdown formatting with headers, bullet points, and bold text for readability.''',
        ),
      ]);
      return response.text ?? 'Could not fetch details. Please try again.';
    } catch (e) {
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  // ─── Mock responses ──────────────────────────────────────────────────────

  String _getMockSchemeResponse(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('pm-kisan') || lower.contains('kisan')) {
      return '''## PM-KISAN Scheme 🌾

**Pradhan Mantri Kisan Samman Nidhi** provides income support to farmer families.

### Benefits
- ₹6,000 per year in three equal installments of ₹2,000
- Directly transferred to bank account

### Eligibility
- All landholding farmer families
- Subject to certain exclusion criteria

### How to Apply
1. Visit your nearest Common Service Centre (CSC)
2. Or apply online at **pmkisan.gov.in**
3. Keep Aadhaar card and land records ready

Would you like to know about other schemes you might be eligible for?''';
    }
    return '''Welcome to Pragati Connect's Scheme Assistant! 🙏

I can help you discover government schemes you may be eligible for. Here are some popular ones:

- **PM-KISAN** — ₹6,000/year for farmers
- **PMAY** — Affordable housing assistance
- **PM Vishwakarma** — Support for traditional artisans
- **MGNREGA** — Guaranteed employment scheme

Tell me about your occupation and location, and I'll find the best schemes for you!

> **Note:** Connect a Gemini API key for full AI-powered assistance.''';
  }

  String _getMockBusinessResponse(
    String name,
    String type, {
    required String location,
    required String language,
  }) {
    final safeLocation = location.trim().isEmpty ? 'your local area' : location.trim();

    if (language == 'hi') {
      return '''# $name — व्यवसाय प्रोफ़ाइल

## परिचय
$name एक भरोसेमंद $type व्यवसाय है, जो $safeLocation में गुणवत्तापूर्ण सेवा देने पर केंद्रित है।

## टैगलाइन
*"गुणवत्ता का वादा, भरोसेमंद सेवा"*

## मुख्य सेवाएँ
- गुणवत्तापूर्ण काम
- ग्राहक की ज़रूरत के अनुसार कस्टम सेवा
- समय पर डिलीवरी

## सोशल मीडिया बायो
$name | $type | $safeLocation

## मार्केटिंग टिप्स
1. **WhatsApp Business प्रोफ़ाइल बनाएं**
2. **संतुष्ट ग्राहकों की प्रतिक्रिया साझा करें**
3. **त्योहारों/मौसम के अनुसार ऑफ़र दें**

> **Note:** बेहतर, व्यक्तिगत कंटेंट के लिए Gemini API key जोड़ें।''';
    }

    return '''# $name — Business Profile

## About
$name is a trusted $type business focused on delivering quality services in $safeLocation.

## Tagline
*"Quality You Can Trust, Service You Can Rely On"*

## Key Services
- High-quality workmanship
- Custom solutions for customer needs
- Timely delivery and support

## Social Media Bio
$name | $type | $safeLocation

## Marketing Tips
1. **Create a WhatsApp Business profile**
2. **Show customer testimonials and before/after photos**
3. **Run seasonal offers for repeat buyers**

> **Note:** Connect a Gemini API key for personalized content.''';
  }

  String _getMockChatResponse(String message) {
    return '''I'm Pragati Connect's AI Assistant! 🙏

I can help you with:
- **Government schemes** and welfare programs
- **Business advice** for micro-entrepreneurs
- **Document understanding** — attach images or PDFs
- **General questions** about livelihoods and rights

> **Note:** Connect a Gemini API key for full AI-powered assistance.''';
  }

  String _getMockVoiceResponse(String spokenText) {
    return 'I heard you say: "$spokenText". For full AI responses, please configure your Gemini API key.';
  }

  List<Map<String, dynamic>> _getMockSchemes({String language = 'en'}) {
    if (language == 'hi') {
      return [
        {
          'name': 'पीएम-किसान',
          'description':
              'किसान परिवारों को तीन समान किस्तों में प्रति वर्ष ₹6,000 की आय सहायता प्रदान करता है।',
          'category': 'Agriculture',
          'ministry': 'कृषि मंत्रालय',
          'benefitAmount': '₹6,000/वर्ष',
        },
        {
          'name': 'प्रधानमंत्री आवास योजना (PMAY)',
          'description':
              'शहरी और ग्रामीण गरीबों के लिए ₹2.67 लाख तक की वित्तीय सहायता।',
          'category': 'Housing',
          'ministry': 'आवास मंत्रालय',
          'benefitAmount': '₹2.67 लाख तक',
        },
        {
          'name': 'पीएम विश्वकर्मा योजना',
          'description':
              'पारंपरिक कारीगरों को प्रशिक्षण, उपकरण और ऋण का समर्थन।',
          'category': 'Business',
          'ministry': 'MSME मंत्रालय',
          'benefitAmount': '₹3 लाख तक ऋण',
        },
        {
          'name': 'मनरेगा',
          'description':
              'ग्रामीण परिवारों को प्रति वर्ष 100 दिन की मजदूरी रोजगार की गारंटी।',
          'category': 'Employment',
          'ministry': 'ग्रामीण विकास मंत्रालय',
          'benefitAmount': '100 दिन गारंटी रोजगार',
        },
        {
          'name': 'आयुष्मान भारत (PM-JAY)',
          'description': 'प्रति परिवार प्रति वर्ष ₹5 लाख का स्वास्थ्य बीमा।',
          'category': 'Health',
          'ministry': 'स्वास्थ्य मंत्रालय',
          'benefitAmount': '₹5 लाख/वर्ष स्वास्थ्य कवर',
        },
        {
          'name': 'पीएम जन धन योजना',
          'description':
              'शून्य शेष बैंक खाते, RuPay डेबिट कार्ड और ₹2 लाख का दुर्घटना बीमा।',
          'category': 'Social Security',
          'ministry': 'वित्त मंत्रालय',
          'benefitAmount': 'निःशुल्क बैंक खाता + बीमा',
        },
        {
          'name': 'स्किल इंडिया मिशन',
          'description':
              'युवाओं के लिए विभिन्न व्यापारों में निःशुल्क कौशल प्रशिक्षण।',
          'category': 'Education',
          'ministry': 'कौशल विकास मंत्रालय',
          'benefitAmount': 'निःशुल्क प्रशिक्षण + प्रमाण पत्र',
        },
        {
          'name': 'पीएम स्वनिधि',
          'description':
              'रेहड़ी-पटरी विक्रेताओं के लिए ₹50,000 तक का सूक्ष्म-ऋण।',
          'category': 'Business',
          'ministry': 'आवास मंत्रालय',
          'benefitAmount': '₹50,000 तक ऋण',
        },
      ];
    }
    return [
      {
        'name': 'PM-KISAN',
        'description':
            'Provides ₹6,000 per year income support to farmer families in three equal installments.',
        'category': 'Agriculture',
        'ministry': 'Ministry of Agriculture',
        'benefitAmount': '₹6,000/year',
      },
      {
        'name': 'Pradhan Mantri Awas Yojana (PMAY)',
        'description':
            'Affordable housing for urban and rural poor with financial assistance up to ₹2.67 lakh.',
        'category': 'Housing',
        'ministry': 'Ministry of Housing',
        'benefitAmount': 'Up to ₹2.67 lakh',
      },
      {
        'name': 'PM Vishwakarma Yojana',
        'description':
            'Support for traditional artisans and craftspeople with training, tools, and credit.',
        'category': 'Business',
        'ministry': 'Ministry of MSME',
        'benefitAmount': 'Up to ₹3 lakh loan',
      },
      {
        'name': 'MGNREGA',
        'description':
            'Guarantees 100 days of wage employment per year to rural households.',
        'category': 'Employment',
        'ministry': 'Ministry of Rural Development',
        'benefitAmount': '100 days guaranteed work',
      },
      {
        'name': 'Ayushman Bharat (PM-JAY)',
        'description':
            'Health insurance of ₹5 lakh per family per year for secondary and tertiary care.',
        'category': 'Health',
        'ministry': 'Ministry of Health',
        'benefitAmount': '₹5 lakh/year health cover',
      },
      {
        'name': 'PM Jan Dhan Yojana',
        'description':
            'Zero-balance bank accounts with RuPay debit card and ₹2 lakh accident insurance.',
        'category': 'Social Security',
        'ministry': 'Ministry of Finance',
        'benefitAmount': 'Free bank account + insurance',
      },
      {
        'name': 'Skill India Mission',
        'description':
            'Free skill training and certification for youth in various trades and professions.',
        'category': 'Education',
        'ministry': 'Ministry of Skill Development',
        'benefitAmount': 'Free training + certificate',
      },
      {
        'name': 'PM SVANidhi',
        'description':
            'Micro-credit facility for street vendors with loans up to ₹50,000.',
        'category': 'Business',
        'ministry': 'Ministry of Housing',
        'benefitAmount': 'Up to ₹50,000 loan',
      },
    ];
  }

  String _getMockSchemeDetails(String schemeName) {
    return '''## $schemeName

### Overview
$schemeName is a Government of India welfare scheme designed to support the informal workforce.

### Key Benefits
- Financial assistance for eligible beneficiaries
- Direct Benefit Transfer to bank accounts
- Easy application process

### Eligibility
- Indian citizens in the informal sector
- Valid Aadhaar card required
- Specific criteria vary by scheme

### How to Apply
1. Visit the official scheme website
2. Register with required documents
3. Submit application online or at CSC

### Documents Required
- Aadhaar Card
- Bank account details
- Income certificate

> **Note:** Connect a Gemini API key for detailed, up-to-date information.''';
  }

  /// Get language-specific instructions for AI prompts
  String _getLanguageInstructions(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'hi':
        return 'Please provide the response in Hindi (हिंदी).';
      case 'mr':
        return 'Please provide the response in Marathi (मराठी).';
      case 'ta':
        return 'Please provide the response in Tamil (தமிழ்).';
      case 'te':
        return 'Please provide the response in Telugu (తెలుగు).';
      case 'bn':
        return 'Please provide the response in Bengali (বাংলা).';
      case 'gu':
        return 'Please provide the response in Gujarati (ગુજરાતી).';
      case 'pa':
        return 'Please provide the response in Punjabi (ਪੰਜਾਬੀ).';
      case 'en':
      default:
        return 'Please provide the response in English.';
    }
  }}