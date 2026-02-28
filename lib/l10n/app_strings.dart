import 'package:flutter/widgets.dart';

/// Simple map-based localization for EN/HI.
/// Usage: S.of(context).get('key')
class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // App
      'app_name': 'Pragati Connect',
      'welcome_back': 'Welcome back',
      'empowering': "Let's empower\nIndia",
      'informal_workforce': 'Informal\nWorkforce',

      // Dashboard
      'dashboard': 'Dashboard',
      'government_schemes': 'Government\nSchemes',
      'government_schemes_desc':
          'Discover and apply for PM-KISAN, Weaver Welfare, and other safety nets tailored to your profile.',
      'voice_assistant': 'Voice Assistant',
      'voice_assistant_desc':
          'Speak in your local language to get answers about wages and rights.',
      'business_boost': 'Business Boost',
      'business_boost_desc':
          'Create a digital identity for your micro-business.',
      'ai_chatbot': 'AI Chatbot',
      'ai_chatbot_desc':
          'Chat with AI assistant, attach files, and get instant help.',
      'impact_metrics': 'Impact Metrics',
      'impact_desc': 'Real-time impact on the informal economy sector.',
      'income_uplift': 'Income Uplift',
      'awareness': 'Awareness',

      // Scheme Assistant
      'scheme_assistant': 'Scheme Assistant',
      'ask_schemes': 'Ask about government schemes...',
      'new_conversation': 'New conversation',
      'demo_mode_msg':
          'Using demo mode. Add your Gemini API key for full AI responses.',

      // Schemes
      'schemes': 'Government Schemes',
      'search_schemes': 'Search schemes...',
      'loading_schemes': 'Loading schemes...',
      'eligibility': 'Eligibility',
      'benefits': 'Benefits',
      'how_to_apply': 'How to Apply',
      'documents_required': 'Documents Required',
      'scheme_details': 'Scheme Details',

      // Voice Assistant
      'tap_to_speak': 'Tap to speak',
      'listening': 'Listening...',
      'thinking': 'Thinking...',
      'speaking': 'Speaking...',
      'ready': 'Ready',

      // Business Boost
      'boost_your_business': 'Boost Your Business',
      'boost_desc':
          'Generate a professional business profile and marketing content using AI.',
      'business_name': 'Business Name',
      'business_type': 'Business Type',
      'location': 'Location',
      'business_description': 'Business Description',
      'generate_profile': 'Generate Profile',
      'generating': 'Generating…',
      'generated_profile': 'Generated Profile',
      'copied': 'Copied to clipboard!',
      'required_field': 'Required',

      // AI Chat
      'ai_chat': 'AI Chat',
      'type_message': 'Type a message...',
      'attach_file': 'Attach File',
      'take_photo': 'Take Photo',
      'choose_file': 'Choose File',
      'welcome_message':
          'Namaste! \ud83d\ude4f I\'m your AI assistant. Ask me anything — government services, business tips, or attach images and files for help!\n\nHow can I assist you today?',
      'new_chat_started_message':
          'New chat started! How can I help you? \ud83d\ude4f',

      // Settings
      'settings': 'Settings',
      'appearance': 'Appearance',
      'language': 'Language',
      'light': 'Light',
      'light_desc': 'Classic bright interface',
      'dark': 'Dark',
      'dark_desc': 'Easier on the eyes',
      'english': 'English',
      'english_desc': 'Interface in English',
      'hindi': 'हिंदी',
      'hindi_desc': 'इंटरफ़ेस हिंदी में',
      'about': 'About',
      'version': 'Version',
      'ai_engine': 'AI Engine',
      'made_with': 'Made with',
      'support': 'Support',
      'help_faq': 'Help & FAQ',
      'privacy_policy': 'Privacy Policy',
      'terms': 'Terms of Service',

      // Profile
      'profile': 'Profile',
      'name': 'Name',
      'occupation': 'Occupation',
      'gender': 'Gender',
      'aadhaar_no': 'Aadhaar No.',
      'phone_no': 'Phone No.',
      'personal_info': 'Personal Information',
      'read_only_info': 'Verified Information',
      'account_actions': 'Account',
      'reset_account': 'Reset Profile',
      'delete_account': 'Delete Account',
      'reset_confirm':
          'This will clear all your profile data including name, photo, and preferences. This cannot be undone.',
      'delete_confirm':
          'This will permanently delete all your data including profile, chat history, and app settings. This cannot be undone.',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'male': 'Male',
      'female': 'Female',
      'other_gender': 'Other',
      'not_set': 'Not set',
      'profile_picture': 'Profile Picture',
      'edit_profile': 'Edit Profile',
      'change_photo': 'Change Photo',
      'adjust_size': 'Adjust Size',
      'preview': 'Preview',
      'choose_photo': 'Choose Photo',
      'invalid_aadhaar': 'Invalid format. Aadhaar must be exactly 12 digits.',
      'invalid_phone':
          'Invalid format. Phone number must be exactly 10 digits.',
      'aadhaar_format': 'Format: 1234 XXXX 1234',
      'phone_format': 'Format: 98XXX XXXXX',
      'set_photo': 'Set Photo',
      'pinch_zoom_hint': 'Pinch to zoom • Drag to move',
    },
    'hi': {
      // App
      'app_name': 'प्रगति कनेक्ट',
      'welcome_back': 'वापस स्वागत है',
      'empowering': 'आइए भारत को\nसशक्त बनाएं',
      'informal_workforce': 'अनौपचारिक\nकार्यबल',

      // Dashboard
      'dashboard': 'डैशबोर्ड',
      'government_schemes': 'सरकारी\nयोजनाएं',
      'government_schemes_desc':
          'PM-KISAN, बुनकर कल्याण और अपनी प्रोफ़ाइल के अनुसार अन्य सुरक्षा योजनाओं की खोज करें।',
      'voice_assistant': 'वॉइस असिस्टेंट',
      'voice_assistant_desc':
          'मजदूरी और अधिकारों के बारे में जवाब पाने के लिए अपनी स्थानीय भाषा में बोलें।',
      'business_boost': 'बिज़नेस बूस्ट',
      'business_boost_desc': 'अपने माइक्रो-बिज़नेस के लिए डिजिटल पहचान बनाएं।',
      'ai_chatbot': 'AI चैटबॉट',
      'ai_chatbot_desc':
          'AI सहायक से चैट करें, फ़ाइलें संलग्न करें, और तुरंत मदद पाएं।',
      'impact_metrics': 'प्रभाव मेट्रिक्स',
      'impact_desc': 'अनौपचारिक अर्थव्यवस्था क्षेत्र पर वास्तविक प्रभाव।',
      'income_uplift': 'आय वृद्धि',
      'awareness': 'जागरूकता',

      // Scheme Assistant
      'scheme_assistant': 'योजना सहायक',
      'ask_schemes': 'सरकारी योजनाओं के बारे में पूछें...',
      'new_conversation': 'नई बातचीत',
      'demo_mode_msg':
          'डेमो मोड में। पूर्ण AI प्रतिक्रियाओं के लिए अपनी Gemini API कुंजी जोड़ें।',

      // Schemes
      'schemes': 'सरकारी योजनाएं',
      'search_schemes': 'योजनाएं खोजें...',
      'loading_schemes': 'योजनाएं लोड हो रही हैं...',
      'eligibility': 'पात्रता',
      'benefits': 'लाभ',
      'how_to_apply': 'आवेदन कैसे करें',
      'documents_required': 'आवश्यक दस्तावेज़',
      'scheme_details': 'योजना विवरण',

      // Voice Assistant
      'tap_to_speak': 'बोलने के लिए टैप करें',
      'listening': 'सुन रहा है...',
      'thinking': 'सोच रहा है...',
      'speaking': 'बोल रहा है...',
      'ready': 'तैयार',

      // Business Boost
      'boost_your_business': 'अपना व्यवसाय बढ़ाएं',
      'boost_desc':
          'AI का उपयोग करके पेशेवर व्यवसाय प्रोफ़ाइल और मार्केटिंग सामग्री बनाएं।',
      'business_name': 'व्यवसाय का नाम',
      'business_type': 'व्यवसाय का प्रकार',
      'location': 'स्थान',
      'business_description': 'व्यवसाय विवरण',
      'generate_profile': 'प्रोफ़ाइल बनाएं',
      'generating': 'बना रहा है…',
      'generated_profile': 'बनाई गई प्रोफ़ाइल',
      'copied': 'क्लिपबोर्ड पर कॉपी किया गया!',
      'required_field': 'आवश्यक',

      // AI Chat
      'ai_chat': 'AI चैट',
      'type_message': 'संदेश लिखें...',
      'attach_file': 'फ़ाइल संलग्न करें',
      'take_photo': 'फ़ोटो लें',
      'choose_file': 'फ़ाइल चुनें',
      'welcome_message':
          'नमस्ते! 🙏 मैं आपका AI सहायक हूँ। सरकारी सेवाओं, व्यवसाय सुझावों, या फ़ाइलें संलग्न करें — कुछ भी पूछें!\n\nआज मैं आपकी कैसे मदद कर सकता हूँ?',
      'new_chat_started_message': 'नई चैट शुरू! मैं आपकी कैसे मदद करूँ? 🙏',

      // Settings
      'settings': 'सेटिंग्स',
      'appearance': 'दिखावट',
      'language': 'भाषा',
      'light': 'लाइट',
      'light_desc': 'क्लासिक चमकीला इंटरफ़ेस',
      'dark': 'डार्क',
      'dark_desc': 'आंखों पर आसान',
      'english': 'English',
      'english_desc': 'Interface in English',
      'hindi': 'हिंदी',
      'hindi_desc': 'इंटरफ़ेस हिंदी में',
      'about': 'के बारे में',
      'version': 'संस्करण',
      'ai_engine': 'AI इंजन',
      'made_with': 'इससे बना',
      'support': 'सहायता',
      'help_faq': 'सहायता और FAQ',
      'privacy_policy': 'गोपनीयता नीति',
      'terms': 'सेवा की शर्तें',

      // Profile
      'profile': 'प्रोफ़ाइल',
      'name': 'नाम',
      'occupation': 'व्यवसाय',
      'gender': 'लिंग',
      'aadhaar_no': 'आधार नं.',
      'phone_no': 'फ़ोन नं.',
      'personal_info': 'व्यक्तिगत जानकारी',
      'read_only_info': 'सत्यापित जानकारी',
      'account_actions': 'खाता',
      'reset_account': 'प्रोफ़ाइल रीसेट करें',
      'delete_account': 'खाता हटाएं',
      'reset_confirm':
          'यह आपके सभी प्रोफ़ाइल डेटा को मिटा देगा। यह पूर्ववत नहीं किया जा सकता।',
      'delete_confirm':
          'यह आपके सभी डेटा को स्थायी रूप से हटा देगा। यह पूर्ववत नहीं किया जा सकता।',
      'cancel': 'रद्द करें',
      'confirm': 'पुष्टि करें',
      'save': 'सहेजें',
      'male': 'पुरुष',
      'female': 'महिला',
      'other_gender': 'अन्य',
      'not_set': 'सेट नहीं',
      'profile_picture': 'प्रोफ़ाइल फ़ोटो',
      'edit_profile': 'प्रोफ़ाइल संपादित करें',
      'change_photo': 'फ़ोटो बदलें',
      'adjust_size': 'आकार समायोजित करें',
      'preview': 'पूर्वावलोकन',
      'choose_photo': 'फ़ोटो चुनें',
      'invalid_aadhaar':
          'अमान्य प्रारूप। आधार नंबर ठीक 12 अंकों का होना चाहिए।',
      'invalid_phone': 'अमान्य प्रारूप। फ़ोन नंबर ठीक 10 अंकों का होना चाहिए।',
      'aadhaar_format': 'प्रारूप: 1234 XXXX 1234',
      'phone_format': 'प्रारूप: 98XXX XXXXX',
      'set_photo': 'फ़ोटो सेट करें',
      'pinch_zoom_hint':
          'ज़ूम करने के लिए पिंच करें • मूव करने के लिए ड्रैग करें',
    },
  };

  final String _lang;
  const AppStrings._(this._lang);

  String get(String key) =>
      _strings[_lang]?[key] ?? _strings['en']![key] ?? key;

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings._(locale.languageCode);
  }
}

typedef S = AppStrings;
