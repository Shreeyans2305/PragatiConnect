import 'package:flutter/widgets.dart';

/// Simple map-based localization for EN/HI.
/// Usage: S.of(context).get('key')
class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // App
      'app_name': 'Pragati Connect',
      'welcome_back': 'Welcome back',
      'empowering': "Empowering\nIndia's",
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
      'hindi_desc': 'Interface in Hindi',
      'marathi': 'मराठी',
      'marathi_desc': 'Interface in Marathi',
      'tamil': 'தமிழ்',
      'tamil_desc': 'Interface in Tamil',
      'telugu': 'తెలుగు',
      'telugu_desc': 'Interface in Telugu',
      'bengali': 'বাংলা',
      'bengali_desc': 'Interface in Bengali',
      'about': 'About',
      'version': 'Version',
      'ai_engine': 'AI Engine',
      'made_with': 'Made with',
      'support': 'Support',
      'help_faq': 'Help & FAQ',
      'privacy_policy': 'Privacy Policy',
      'terms': 'Terms of Service',

      // Edit Profile
      'edit_profile': 'Edit Profile',
      'save': 'Save',
      'profile_saved': 'Profile saved successfully!',
      'personal_info': 'Personal Information',
      'name': 'Name',
      'state': 'State',
      'occupation': 'Occupation',
      'primary_trade': 'Primary Trade',
      'secondary_trades': 'Secondary Trades (Optional)',
      'language_preference': 'Language Preference',
      'preferred_language': 'Preferred Language',
      'notifications': 'Notifications',
      'whatsapp_updates': 'WhatsApp Updates',
      'whatsapp_updates_desc': 'Receive scheme alerts and tips via WhatsApp',
    },
    'hi': {
      // App
      'app_name': 'प्रगति कनेक्ट',
      'welcome_back': 'वापस स्वागत है',
      'empowering': 'भारत के\nअनौपचारिक',
      'informal_workforce': 'कार्यबल को\nसशक्त बनाना',

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
      'english_desc': 'अंग्रेजी में इंटरफ़ेस',
      'hindi': 'हिंदी',
      'hindi_desc': 'हिंदी में इंटरफ़ेस',
      'marathi': 'मराठी',
      'marathi_desc': 'मराठी में इंटरफ़ेस',
      'tamil': 'தமிழ்',
      'tamil_desc': 'तमिल में इंटरफ़ेस',
      'telugu': 'తెలుగు',
      'telugu_desc': 'तेलुगु में इंटरफ़ेस',
      'bengali': 'বাংলা',
      'bengali_desc': 'बंगाली में इंटरफ़ेस',
      'about': 'के बारे में',
      'version': 'संस्करण',
      'ai_engine': 'AI इंजन',
      'made_with': 'इससे बना',
      'support': 'सहायता',
      'help_faq': 'सहायता और FAQ',
      'privacy_policy': 'गोपनीयता नीति',
      'terms': 'सेवा की शर्तें',

      // Edit Profile
      'edit_profile': 'प्रोफ़ाइल संपादित करें',
      'save': 'सहेजें',
      'profile_saved': 'प्रोफ़ाइल सफलतापूर्वक सहेजी गई!',
      'personal_info': 'व्यक्तिगत जानकारी',
      'name': 'नाम',
      'state': 'राज्य',
      'occupation': 'व्यवसाय',
      'primary_trade': 'प्राथमिक व्यापार',
      'secondary_trades': 'द्वितीयक व्यापार (वैकल्पिक)',
      'language_preference': 'भाषा प्राथमिकता',
      'preferred_language': 'पसंदीदा भाषा',
      'notifications': 'सूचनाएं',
      'whatsapp_updates': 'व्हाट्सएप अपडेट',
      'whatsapp_updates_desc': 'व्हाट्सएप के माध्यम से योजना अलर्ट और टिप्स प्राप्त करें',
    },
    'ta': {
      // App - Tamil
      'app_name': 'பிரகதி கனெக்ட்',
      'welcome_back': 'மீண்டும் வரவேற்கிறோம்',
      'empowering': 'இந்தியாவின்',
      'informal_workforce': 'முறைசாரா\nதொழிலாளர்கள்',

      // Dashboard
      'dashboard': 'டாஷ்போர்டு',
      'government_schemes': 'அரசு\nதிட்டங்கள்',
      'government_schemes_desc':
          'PM-KISAN, நெசவாளர் நலத்திட்டம் போன்ற திட்டங்களை கண்டறியுங்கள்.',
      'voice_assistant': 'குரல் உதவியாளர்',
      'voice_assistant_desc': 'உங்கள் மொழியில் பேசி பதில் பெறுங்கள்.',
      'business_boost': 'வணிக ஊக்கம்',
      'business_boost_desc': 'உங்கள் வணிகத்திற்கு டிஜிட்டல் அடையாளம் உருவாக்குங்கள்.',
      'ai_chatbot': 'AI சாட்பாட்',
      'ai_chatbot_desc': 'AI உதவியாளரிடம் உரையாடுங்கள்.',
      'impact_metrics': 'தாக்க அளவீடுகள்',
      'impact_desc': 'முறைசாரா பொருளாதாரத்தில் உண்மையான தாக்கம்.',
      'income_uplift': 'வருமான உயர்வு',
      'awareness': 'விழிப்புணர்வு',

      // Scheme Assistant
      'scheme_assistant': 'திட்ட உதவியாளர்',
      'ask_schemes': 'அரசு திட்டங்கள் பற்றி கேளுங்கள்...',
      'new_conversation': 'புதிய உரையாடல்',
      'demo_mode_msg': 'டெமோ பயன்முறையில். முழு AI பதில்களுக்கு API கீ சேர்க்கவும்.',

      // Schemes
      'schemes': 'அரசு திட்டங்கள்',
      'search_schemes': 'திட்டங்களைத் தேடுங்கள்...',
      'loading_schemes': 'திட்டங்கள் ஏற்றப்படுகின்றன...',
      'eligibility': 'தகுதி',
      'benefits': 'நன்மைகள்',
      'how_to_apply': 'எப்படி விண்ணப்பிப்பது',
      'documents_required': 'தேவையான ஆவணங்கள்',
      'scheme_details': 'திட்ட விவரங்கள்',

      // Voice Assistant
      'tap_to_speak': 'பேச தட்டவும்',
      'listening': 'கேட்கிறது...',
      'thinking': 'சிந்திக்கிறது...',
      'speaking': 'பேசுகிறது...',
      'ready': 'தயார்',

      // Business Boost
      'boost_your_business': 'உங்கள் வணிகத்தை வளர்க்கவும்',
      'boost_desc': 'AI பயன்படுத்தி தொழில்முறை வணிக சுயவிவரம் உருவாக்குங்கள்.',
      'business_name': 'வணிகப் பெயர்',
      'business_type': 'வணிக வகை',
      'location': 'இடம்',
      'business_description': 'வணிக விவரம்',
      'generate_profile': 'சுயவிவரம் உருவாக்கு',
      'generating': 'உருவாக்குகிறது…',
      'generated_profile': 'உருவாக்கப்பட்ட சுயவிவரம்',
      'copied': 'கிளிப்போர்டுக்கு நகலெடுக்கப்பட்டது!',
      'required_field': 'தேவை',

      // AI Chat
      'ai_chat': 'AI சாட்',
      'type_message': 'செய்தி தட்டச்சு செய்யவும்...',
      'attach_file': 'கோப்பை இணைக்கவும்',
      'take_photo': 'புகைப்படம் எடு',
      'choose_file': 'கோப்பைத் தேர்ந்தெடுக்கவும்',
      'welcome_message':
          'வணக்கம்! 🙏 நான் உங்கள் AI உதவியாளர். எதையும் கேளுங்கள்!\n\nஇன்று நான் உங்களுக்கு எப்படி உதவ முடியும்?',
      'new_chat_started_message': 'புதிய சாட் தொடங்கியது! நான் எப்படி உதவ முடியும்? 🙏',

      // Settings
      'settings': 'அமைப்புகள்',
      'appearance': 'தோற்றம்',
      'language': 'மொழி',
      'light': 'லைட்',
      'light_desc': 'பிரகாசமான இடைமுகம்',
      'dark': 'டார்க்',
      'dark_desc': 'கண்களுக்கு எளிதானது',
      'english': 'English',
      'english_desc': 'ஆங்கிலத்தில் இடைமுகம்',
      'hindi': 'हिंदी',
      'hindi_desc': 'இந்தியில் இடைமுகம்',
      'marathi': 'मराठी',
      'marathi_desc': 'மராத்தியில் இடைமுகம்',
      'tamil': 'தமிழ்',
      'tamil_desc': 'தமிழில் இடைமுகம்',
      'telugu': 'తెలుగు',
      'telugu_desc': 'தெலுங்கில் இடைமுகம்',
      'bengali': 'বাংলা',
      'bengali_desc': 'வங்காளத்தில் இடைமுகம்',
      'about': 'பற்றி',
      'version': 'பதிப்பு',
      'ai_engine': 'AI இயந்திரம்',
      'made_with': 'இதனால் உருவாக்கப்பட்டது',
      'support': 'ஆதரவு',
      'help_faq': 'உதவி & FAQ',
      'privacy_policy': 'தனியுரிமைக் கொள்கை',
      'terms': 'சேவை விதிமுறைகள்',

      // Edit Profile
      'edit_profile': 'சுயவிவரத்தைத் திருத்து',
      'save': 'சேமி',
      'profile_saved': 'சுயவிவரம் வெற்றிகரமாக சேமிக்கப்பட்டது!',
      'personal_info': 'தனிப்பட்ட தகவல்',
      'name': 'பெயர்',
      'state': 'மாநிலம்',
      'occupation': 'தொழில்',
      'primary_trade': 'முதன்மை தொழில்',
      'secondary_trades': 'இரண்டாம் நிலை தொழில்கள் (விரும்பினால்)',
      'language_preference': 'மொழி விருப்பம்',
      'preferred_language': 'விரும்பிய மொழி',
      'notifications': 'அறிவிப்புகள்',
      'whatsapp_updates': 'வாட்ஸ்அப் புதுப்பிப்புகள்',
      'whatsapp_updates_desc': 'வாட்ஸ்அப் மூலம் திட்ட விழிப்பூட்டல்களைப் பெறுங்கள்',
    },
    'te': {
      // App - Telugu
      'app_name': 'ప్రగతి కనెక్ట్',
      'welcome_back': 'తిరిగి స్వాగతం',
      'empowering': 'భారతదేశం',
      'informal_workforce': 'అనధికారిక\nశ్రామికశక్తి',

      // Dashboard
      'dashboard': 'డాష్‌బోర్డ్',
      'government_schemes': 'ప్రభుత్వ\nపథకాలు',
      'government_schemes_desc': 'PM-KISAN, నేత కార్మిక సంక్షేమం వంటి పథకాలను కనుగొనండి.',
      'voice_assistant': 'వాయిస్ అసిస్టెంట్',
      'voice_assistant_desc': 'మీ భాషలో మాట్లాడి సమాధానాలు పొందండి.',
      'business_boost': 'వ్యాపార బూస్ట్',
      'business_boost_desc': 'మీ వ్యాపారానికి డిజిటల్ గుర్తింపు సృష్టించండి.',
      'ai_chatbot': 'AI చాట్‌బాట్',
      'ai_chatbot_desc': 'AI సహాయకంతో చాట్ చేయండి.',
      'impact_metrics': 'ప్రభావ కొలమానాలు',
      'impact_desc': 'అనధికారిక ఆర్థిక వ్యవస్థపై నిజమైన ప్రభావం.',
      'income_uplift': 'ఆదాయ పెరుగుదల',
      'awareness': 'అవగాహన',

      // Scheme Assistant
      'scheme_assistant': 'పథకం సహాయకుడు',
      'ask_schemes': 'ప్రభుత్వ పథకాల గురించి అడగండి...',
      'new_conversation': 'కొత్త సంభాషణ',
      'demo_mode_msg': 'డెమో మోడ్‌లో. పూర్తి AI ప్రతిస్పందనల కోసం API కీ జోడించండి.',

      // Schemes
      'schemes': 'ప్రభుత్వ పథకాలు',
      'search_schemes': 'పథకాలను శోధించండి...',
      'loading_schemes': 'పథకాలు లోడ్ అవుతున్నాయి...',
      'eligibility': 'అర్హత',
      'benefits': 'ప్రయోజనాలు',
      'how_to_apply': 'ఎలా దరఖాస్తు చేయాలి',
      'documents_required': 'అవసరమైన పత్రాలు',
      'scheme_details': 'పథకం వివరాలు',

      // Voice Assistant
      'tap_to_speak': 'మాట్లాడటానికి నొక్కండి',
      'listening': 'వింటోంది...',
      'thinking': 'ఆలోచిస్తోంది...',
      'speaking': 'మాట్లాడుతోంది...',
      'ready': 'సిద్ధంగా ఉంది',

      // Business Boost
      'boost_your_business': 'మీ వ్యాపారాన్ని పెంచుకోండి',
      'boost_desc': 'AI ఉపయోగించి ప్రొఫెషనల్ వ్యాపార ప్రొఫైల్ సృష్టించండి.',
      'business_name': 'వ్యాపార పేరు',
      'business_type': 'వ్యాపార రకం',
      'location': 'స్థానం',
      'business_description': 'వ్యాపార వివరణ',
      'generate_profile': 'ప్రొఫైల్ రూపొందించండి',
      'generating': 'రూపొందిస్తోంది…',
      'generated_profile': 'రూపొందించిన ప్రొఫైల్',
      'copied': 'క్లిప్‌బోర్డ్‌కు కాపీ చేయబడింది!',
      'required_field': 'అవసరం',

      // AI Chat
      'ai_chat': 'AI చాట్',
      'type_message': 'సందేశం టైప్ చేయండి...',
      'attach_file': 'ఫైల్ జోడించండి',
      'take_photo': 'ఫోటో తీయండి',
      'choose_file': 'ఫైల్ ఎంచుకోండి',
      'welcome_message':
          'నమస్కారం! 🙏 నేను మీ AI సహాయకుడిని. ఏదైనా అడగండి!\n\nఈరోజు నేను మీకు ఎలా సహాయపడగలను?',
      'new_chat_started_message': 'కొత్త చాట్ ప్రారంభమైంది! నేను ఎలా సహాయపడగలను? 🙏',

      // Settings
      'settings': 'సెట్టింగ్‌లు',
      'appearance': 'రూపం',
      'language': 'భాష',
      'light': 'లైట్',
      'light_desc': 'ప్రకాశవంతమైన ఇంటర్‌ఫేస్',
      'dark': 'డార్క్',
      'dark_desc': 'కళ్ళకు సులభం',
      'english': 'English',
      'english_desc': 'ఆంగ్లంలో ఇంటర్‌ఫేస్',
      'hindi': 'हिंदी',
      'hindi_desc': 'హిందీలో ఇంటర్‌ఫేస్',
      'marathi': 'मराठी',
      'marathi_desc': 'మరాఠీలో ఇంటర్‌ఫేస్',
      'tamil': 'தமிழ்',
      'tamil_desc': 'తమిళంలో ఇంటర్‌ఫేస్',
      'telugu': 'తెలుగు',
      'telugu_desc': 'తెలుగులో ఇంటర్‌ఫేస్',
      'bengali': 'বাংলা',
      'bengali_desc': 'బెంగాలీలో ఇంటర్‌ఫేస్',
      'about': 'గురించి',
      'version': 'వెర్షన్',
      'ai_engine': 'AI ఇంజిన్',
      'made_with': 'దీనితో తయారు చేయబడింది',
      'support': 'మద్దతు',
      'help_faq': 'సహాయం & FAQ',
      'privacy_policy': 'గోప్యతా విధానం',
      'terms': 'సేవా నిబంధనలు',

      // Edit Profile
      'edit_profile': 'ప్రొఫైల్ సవరించు',
      'save': 'సేవ్ చేయి',
      'profile_saved': 'ప్రొఫైల్ విజయవంతంగా సేవ్ చేయబడింది!',
      'personal_info': 'వ్యక్తిగత సమాచారం',
      'name': 'పేరు',
      'state': 'రాష్ట్రం',
      'occupation': 'వృత్తి',
      'primary_trade': 'ప్రాథమిక వృత్తి',
      'secondary_trades': 'ద్వితీయ వృత్తులు (ఐచ్ఛికం)',
      'language_preference': 'భాష ప్రాధాన్యత',
      'preferred_language': 'ఇష్టపడే భాష',
      'notifications': 'నోటిఫికేషన్‌లు',
      'whatsapp_updates': 'వాట్సాప్ అప్‌డేట్‌లు',
      'whatsapp_updates_desc': 'వాట్సాప్ ద్వారా పథకం హెచ్చరికలు అందుకోండి',
    },
    'bn': {
      // App - Bengali
      'app_name': 'প্রগতি কানেক্ট',
      'welcome_back': 'আবার স্বাগতম',
      'empowering': 'ভারতের',
      'informal_workforce': 'অনানুষ্ঠানিক\nকর্মশক্তি',

      // Dashboard
      'dashboard': 'ড্যাশবোর্ড',
      'government_schemes': 'সরকারি\nপ্রকল্প',
      'government_schemes_desc': 'PM-KISAN, তাঁতি কল্যাণ প্রকল্প ইত্যাদি খুঁজে বের করুন।',
      'voice_assistant': 'ভয়েস অ্যাসিস্ট্যান্ট',
      'voice_assistant_desc': 'আপনার ভাষায় বলুন, উত্তর পান।',
      'business_boost': 'ব্যবসা বুস্ট',
      'business_boost_desc': 'আপনার ব্যবসার জন্য ডিজিটাল পরিচয় তৈরি করুন।',
      'ai_chatbot': 'AI চ্যাটবট',
      'ai_chatbot_desc': 'AI সহকারীর সাথে চ্যাট করুন।',
      'impact_metrics': 'প্রভাব মেট্রিক্স',
      'impact_desc': 'অনানুষ্ঠানিক অর্থনীতিতে প্রকৃত প্রভাব।',
      'income_uplift': 'আয় বৃদ্ধি',
      'awareness': 'সচেতনতা',

      // Scheme Assistant
      'scheme_assistant': 'প্রকল্প সহায়ক',
      'ask_schemes': 'সরকারি প্রকল্প সম্পর্কে জিজ্ঞাসা করুন...',
      'new_conversation': 'নতুন কথোপকথন',
      'demo_mode_msg': 'ডেমো মোডে। সম্পূর্ণ AI প্রতিক্রিয়ার জন্য API কী যোগ করুন।',

      // Schemes
      'schemes': 'সরকারি প্রকল্প',
      'search_schemes': 'প্রকল্প খুঁজুন...',
      'loading_schemes': 'প্রকল্প লোড হচ্ছে...',
      'eligibility': 'যোগ্যতা',
      'benefits': 'সুবিধা',
      'how_to_apply': 'কিভাবে আবেদন করবেন',
      'documents_required': 'প্রয়োজনীয় নথি',
      'scheme_details': 'প্রকল্পের বিবরণ',

      // Voice Assistant
      'tap_to_speak': 'বলতে ট্যাপ করুন',
      'listening': 'শুনছে...',
      'thinking': 'ভাবছে...',
      'speaking': 'বলছে...',
      'ready': 'প্রস্তুত',

      // Business Boost
      'boost_your_business': 'আপনার ব্যবসা বাড়ান',
      'boost_desc': 'AI ব্যবহার করে পেশাদার ব্যবসায়িক প্রোফাইল তৈরি করুন।',
      'business_name': 'ব্যবসার নাম',
      'business_type': 'ব্যবসার ধরন',
      'location': 'অবস্থান',
      'business_description': 'ব্যবসার বিবরণ',
      'generate_profile': 'প্রোফাইল তৈরি করুন',
      'generating': 'তৈরি হচ্ছে…',
      'generated_profile': 'তৈরি প্রোফাইল',
      'copied': 'ক্লিপবোর্ডে কপি করা হয়েছে!',
      'required_field': 'প্রয়োজনীয়',

      // AI Chat
      'ai_chat': 'AI চ্যাট',
      'type_message': 'বার্তা টাইপ করুন...',
      'attach_file': 'ফাইল সংযুক্ত করুন',
      'take_photo': 'ফটো তুলুন',
      'choose_file': 'ফাইল নির্বাচন করুন',
      'welcome_message':
          'নমস্কার! 🙏 আমি আপনার AI সহায়ক। যেকোনো কিছু জিজ্ঞাসা করুন!\n\nআজ আমি আপনাকে কিভাবে সাহায্য করতে পারি?',
      'new_chat_started_message': 'নতুন চ্যাট শুরু হয়েছে! আমি কিভাবে সাহায্য করতে পারি? 🙏',

      // Settings
      'settings': 'সেটিংস',
      'appearance': 'চেহারা',
      'language': 'ভাষা',
      'light': 'লাইট',
      'light_desc': 'উজ্জ্বল ইন্টারফেস',
      'dark': 'ডার্ক',
      'dark_desc': 'চোখের জন্য আরামদায়ক',
      'english': 'English',
      'english_desc': 'ইংরেজিতে ইন্টারফেস',
      'hindi': 'हिंदी',
      'hindi_desc': 'হিন্দিতে ইন্টারফেস',
      'marathi': 'मराठी',
      'marathi_desc': 'মরাঠিতে ইন্টারফেস',
      'tamil': 'தமிழ்',
      'tamil_desc': 'তামিলে ইন্টারফেস',
      'telugu': 'తెలుగు',
      'telugu_desc': 'তেলুগুতে ইন্টারফেস',
      'bengali': 'বাংলা',
      'bengali_desc': 'বাংলায় ইন্টারফেস',
      'about': 'সম্পর্কে',
      'version': 'সংস্করণ',
      'ai_engine': 'AI ইঞ্জিন',
      'made_with': 'এটি দিয়ে তৈরি',
      'support': 'সহায়তা',
      'help_faq': 'সাহায্য ও FAQ',
      'privacy_policy': 'গোপনীয়তা নীতি',
      'terms': 'সেবার শর্তাবলী',

      // Edit Profile
      'edit_profile': 'প্রোফাইল সম্পাদনা করুন',
      'save': 'সংরক্ষণ করুন',
      'profile_saved': 'প্রোফাইল সফলভাবে সংরক্ষিত হয়েছে!',
      'personal_info': 'ব্যক্তিগত তথ্য',
      'name': 'নাম',
      'state': 'রাজ্য',
      'occupation': 'পেশা',
      'primary_trade': 'প্রাথমিক পেশা',
      'secondary_trades': 'গৌণ পেশা (ঐচ্ছিক)',
      'language_preference': 'ভাষা পছন্দ',
      'preferred_language': 'পছন্দের ভাষা',
      'notifications': 'বিজ্ঞপ্তি',
      'whatsapp_updates': 'হোয়াটসঅ্যাপ আপডেট',
      'whatsapp_updates_desc': 'হোয়াটসঅ্যাপের মাধ্যমে প্রকল্পের সতর্কতা পান',
    },
    'mr': {
      // App - Marathi
      'app_name': 'प्रगती कनेक्ट',
      'welcome_back': 'पुन्हा स्वागत आहे',
      'empowering': 'भारताच्या',
      'informal_workforce': 'अनौपचारिक\nकर्मचाऱ्यांना\nसक्षम करणे',

      // Dashboard
      'dashboard': 'डॅशबोर्ड',
      'government_schemes': 'सरकारी\nयोजना',
      'government_schemes_desc': 'PM-KISAN, विणकर कल्याण आणि इतर योजना शोधा.',
      'voice_assistant': 'व्हॉइस असिस्टंट',
      'voice_assistant_desc': 'तुमच्या भाषेत बोला, उत्तरे मिळवा.',
      'business_boost': 'बिझनेस बूस्ट',
      'business_boost_desc': 'तुमच्या व्यवसायासाठी डिजिटल ओळख तयार करा.',
      'ai_chatbot': 'AI चॅटबॉट',
      'ai_chatbot_desc': 'AI सहाय्यकाशी चॅट करा.',
      'impact_metrics': 'प्रभाव मेट्रिक्स',
      'impact_desc': 'अनौपचारिक अर्थव्यवस्थेवर वास्तविक प्रभाव.',
      'income_uplift': 'उत्पन्न वाढ',
      'awareness': 'जागरूकता',

      // Scheme Assistant
      'scheme_assistant': 'योजना सहाय्यक',
      'ask_schemes': 'सरकारी योजनांबद्दल विचारा...',
      'new_conversation': 'नवीन संवाद',
      'demo_mode_msg': 'डेमो मोडमध्ये. पूर्ण AI प्रतिसादांसाठी API की जोडा.',

      // Schemes
      'schemes': 'सरकारी योजना',
      'search_schemes': 'योजना शोधा...',
      'loading_schemes': 'योजना लोड होत आहेत...',
      'eligibility': 'पात्रता',
      'benefits': 'फायदे',
      'how_to_apply': 'अर्ज कसा करावा',
      'documents_required': 'आवश्यक कागदपत्रे',
      'scheme_details': 'योजना तपशील',

      // Voice Assistant
      'tap_to_speak': 'बोलण्यासाठी टॅप करा',
      'listening': 'ऐकत आहे...',
      'thinking': 'विचार करत आहे...',
      'speaking': 'बोलत आहे...',
      'ready': 'तयार',

      // Business Boost
      'boost_your_business': 'तुमचा व्यवसाय वाढवा',
      'boost_desc': 'AI वापरून व्यावसायिक प्रोफाइल तयार करा.',
      'business_name': 'व्यवसायाचे नाव',
      'business_type': 'व्यवसायाचा प्रकार',
      'location': 'स्थान',
      'business_description': 'व्यवसाय वर्णन',
      'generate_profile': 'प्रोफाइल तयार करा',
      'generating': 'तयार करत आहे…',
      'generated_profile': 'तयार केलेली प्रोफाइल',
      'copied': 'क्लिपबोर्डवर कॉपी केले!',
      'required_field': 'आवश्यक',

      // AI Chat
      'ai_chat': 'AI चॅट',
      'type_message': 'संदेश टाइप करा...',
      'attach_file': 'फाइल जोडा',
      'take_photo': 'फोटो काढा',
      'choose_file': 'फाइल निवडा',
      'welcome_message': 'नमस्कार! 🙏 मी तुमचा AI सहाय्यक आहे. काहीही विचारा!\n\nआज मी तुम्हाला कशी मदत करू शकतो?',
      'new_chat_started_message': 'नवीन चॅट सुरू झाली! मी कशी मदत करू? 🙏',

      // Settings
      'settings': 'सेटिंग्ज',
      'appearance': 'दिसावट',
      'language': 'भाषा',
      'light': 'लाइट',
      'light_desc': 'उजळ इंटरफेस',
      'dark': 'डार्क',
      'dark_desc': 'डोळ्यांसाठी आरामदायक',
      'english': 'English',
      'english_desc': 'इंग्रजीमध्ये इंटरफेस',
      'hindi': 'हिंदी',
      'hindi_desc': 'हिंदीमध्ये इंटरफेस',
      'marathi': 'मराठी',
      'marathi_desc': 'मराठीमध्ये इंटरफेस',
      'tamil': 'தமிழ்',
      'tamil_desc': 'तमिळमध्ये इंटरफेस',
      'telugu': 'తెలుగు',
      'telugu_desc': 'तेलुगूमध्ये इंटरफेस',
      'bengali': 'বাংলা',
      'bengali_desc': 'बंगालीमध्ये इंटरफेस',
      'about': 'बद्दल',
      'version': 'आवृत्ती',
      'ai_engine': 'AI इंजिन',
      'made_with': 'यासह बनवले',
      'support': 'समर्थन',
      'help_faq': 'मदत आणि FAQ',
      'privacy_policy': 'गोपनीयता धोरण',
      'terms': 'सेवा अटी',

      // Edit Profile
      'edit_profile': 'प्रोफाइल संपादित करा',
      'save': 'जतन करा',
      'profile_saved': 'प्रोफाइल यशस्वीरित्या जतन झाली!',
      'personal_info': 'वैयक्तिक माहिती',
      'name': 'नाव',
      'state': 'राज्य',
      'occupation': 'व्यवसाय',
      'primary_trade': 'प्राथमिक व्यवसाय',
      'secondary_trades': 'दुय्यम व्यवसाय (पर्यायी)',
      'language_preference': 'भाषा प्राधान्य',
      'preferred_language': 'पसंतीची भाषा',
      'notifications': 'सूचना',
      'whatsapp_updates': 'व्हाट्सअॅप अपडेट्स',
      'whatsapp_updates_desc': 'व्हाट्सअॅपद्वारे योजना सूचना मिळवा',
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
