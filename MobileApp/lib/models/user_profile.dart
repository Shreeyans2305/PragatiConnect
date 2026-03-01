/// User profile model for PragatiConnect
class UserProfile {
  final String phoneNumber;
  final String? name;
  final String primaryTrade;
  final List<String> secondaryTrades;
  final String location;
  final String state;
  final String preferredLanguage;
  final bool whatsappOptIn;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.phoneNumber,
    this.name,
    required this.primaryTrade,
    this.secondaryTrades = const [],
    required this.location,
    required this.state,
    this.preferredLanguage = 'hi',
    this.whatsappOptIn = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Available trades with display names and icons
  static const Map<String, Map<String, dynamic>> trades = {
    'carpenter': {'name': 'Carpenter', 'nameHi': 'बढ़ई', 'icon': '🪚'},
    'weaver': {'name': 'Weaver', 'nameHi': 'बुनकर', 'icon': '🧵'},
    'potter': {'name': 'Potter', 'nameHi': 'कुम्हार', 'icon': '🏺'},
    'maid': {'name': 'Domestic Worker', 'nameHi': 'घरेलू कामगार', 'icon': '🏠'},
    'cook': {'name': 'Cook', 'nameHi': 'रसोइया', 'icon': '👨‍🍳'},
    'tailor': {'name': 'Tailor', 'nameHi': 'दर्जी', 'icon': '🪡'},
    'farmer': {'name': 'Farmer', 'nameHi': 'किसान', 'icon': '🌾'},
    'electrician': {'name': 'Electrician', 'nameHi': 'इलेक्ट्रीशियन', 'icon': '⚡'},
    'plumber': {'name': 'Plumber', 'nameHi': 'प्लंबर', 'icon': '🔧'},
    'painter': {'name': 'Painter', 'nameHi': 'पेंटर', 'icon': '🎨'},
    'driver': {'name': 'Driver', 'nameHi': 'ड्राइवर', 'icon': '🚗'},
    'vendor': {'name': 'Street Vendor', 'nameHi': 'स्ट्रीट वेंडर', 'icon': '🛒'},
    'small_business': {'name': 'Small Business', 'nameHi': 'छोटा व्यापार', 'icon': '🏪'},
    'artisan': {'name': 'Artisan/Craftsman', 'nameHi': 'कारीगर', 'icon': '🎭'},
    'other': {'name': 'Other', 'nameHi': 'अन्य', 'icon': '💼'},
  };

  /// Indian states list
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Puducherry',
    'Chandigarh',
  ];

  /// Supported languages
  static const Map<String, Map<String, String>> languages = {
    'en': {'name': 'English', 'nativeName': 'English'},
    'hi': {'name': 'Hindi', 'nativeName': 'हिंदी'},
    'mr': {'name': 'Marathi', 'nativeName': 'मराठी'},
    'ta': {'name': 'Tamil', 'nativeName': 'தமிழ்'},
    'te': {'name': 'Telugu', 'nativeName': 'తెలుగు'},
    'bn': {'name': 'Bengali', 'nativeName': 'বাংলা'},
  };

  UserProfile copyWith({
    String? phoneNumber,
    String? name,
    String? primaryTrade,
    List<String>? secondaryTrades,
    String? location,
    String? state,
    String? preferredLanguage,
    bool? whatsappOptIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      primaryTrade: primaryTrade ?? this.primaryTrade,
      secondaryTrades: secondaryTrades ?? this.secondaryTrades,
      location: location ?? this.location,
      state: state ?? this.state,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      whatsappOptIn: whatsappOptIn ?? this.whatsappOptIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'name': name,
      'primary_trade': primaryTrade,
      'secondary_trades': secondaryTrades,
      'location': location,
      'state': state,
      'preferred_language': preferredLanguage,
      'whatsapp_opt_in': whatsappOptIn,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phoneNumber: json['phone_number'] as String,
      name: json['name'] as String?,
      primaryTrade: json['primary_trade'] as String,
      secondaryTrades: (json['secondary_trades'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      location: json['location'] as String,
      state: json['state'] as String,
      preferredLanguage: json['preferred_language'] as String? ?? 'hi',
      whatsappOptIn: json['whatsapp_opt_in'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  String getTradeDisplayName({bool hindi = false}) {
    final trade = trades[primaryTrade];
    if (trade == null) return primaryTrade;
    return hindi ? trade['nameHi'] as String : trade['name'] as String;
  }

  /// Convenience getter for trade display name in English
  String get tradeName => getTradeDisplayName(hindi: false);

  String get tradeIcon => trades[primaryTrade]?['icon'] as String? ?? '💼';
}
