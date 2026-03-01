import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';

/// Onboarding screen for new users
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedTrade = '';
  String _selectedState = '';
  String _selectedLanguage = 'hi';

  // Validation
  bool _phoneValid = false;
  String? _phoneError;

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _phoneValid;
      case 1:
        return _nameController.text.trim().isNotEmpty; // Name is now required
      case 2:
        return _selectedTrade.isNotEmpty;
      case 3:
        return _selectedState.isNotEmpty && _locationController.text.trim().isNotEmpty;
      case 4:
        return _selectedLanguage.isNotEmpty;
      default:
        return false;
    }
  }

  void _validatePhone(String value) {
    // Indian phone number validation (10 digits)
    final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    setState(() {
      if (cleanNumber.isEmpty) {
        _phoneValid = false;
        _phoneError = null;
      } else if (cleanNumber.length != 10) {
        _phoneValid = false;
        _phoneError = 'Phone number must be 10 digits';
      } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanNumber)) {
        _phoneValid = false;
        _phoneError = 'Invalid Indian phone number';
      } else {
        _phoneValid = true;
        _phoneError = null;
      }
    });
  }

  Future<void> _completeOnboarding() async {
    final userProvider = context.read<UserProvider>();
    final localeProvider = context.read<LocaleProvider>();

    final profile = UserProfile(
      phoneNumber: '+91${_phoneController.text.replaceAll(RegExp(r'[^\d]'), '')}',
      name: _nameController.text.isEmpty ? null : _nameController.text,
      primaryTrade: _selectedTrade,
      location: _locationController.text,
      state: _selectedState,
      preferredLanguage: _selectedLanguage,
    );

    await userProvider.saveProfile(profile);
    localeProvider.setLocaleByCode(_selectedLanguage);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  Future<void> _skipOnboarding() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.skipOnboarding();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHindi = context.watch<LocaleProvider>().isHindi;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    isHindi ? 'छोड़ें' : 'Skip',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPhonePage(theme, isHindi),
                  _buildNamePage(theme, isHindi),
                  _buildTradePage(theme, isHindi),
                  _buildLocationPage(theme, isHindi),
                  _buildLanguagePage(theme, isHindi),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(isHindi ? 'पीछे' : 'Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage > 0 ? 2 : 1,
                    child: FilledButton(
                      onPressed: _canProceed()
                          ? (_currentPage == 4
                              ? _completeOnboarding
                              : _nextPage)
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage == 4
                            ? (isHindi ? 'शुरू करें' : 'Get Started')
                            : (isHindi ? 'आगे' : 'Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhonePage(ThemeData theme, bool isHindi) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(height: 24),
          Text(
            isHindi ? 'अपना फोन नंबर दर्ज करें' : 'Enter your phone number',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? 'हम आपकी प्रोफ़ाइल को आपके फ़ोन नंबर से जोड़ेंगे'
                : 'We\'ll link your profile to your phone number',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: _validatePhone,
            decoration: InputDecoration(
              labelText: isHindi ? 'फोन नंबर' : 'Phone Number',
              prefixText: '+91 ',
              prefixIcon: const Icon(Icons.phone),
              errorText: _phoneError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _buildNamePage(ThemeData theme, bool isHindi) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(height: 24),
          Text(
            isHindi ? 'आपका नाम क्या है?' : 'What\'s your name?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? 'आपकी प्रोफ़ाइल के लिए आपका नाम'
                : 'Your name for your profile',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: isHindi ? 'नाम' : 'Name',
              prefixIcon: const Icon(Icons.badge),
              border: const OutlineInputBorder(),
              hintText: isHindi ? 'अपना नाम दर्ज करें' : 'Enter your name',
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _buildTradePage(ThemeData theme, bool isHindi) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.work,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'आप क्या काम करते हैं?' : 'What work do you do?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? 'अपना मुख्य व्यवसाय चुनें'
                : 'Select your primary occupation',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: UserProfile.trades.length,
              itemBuilder: (context, index) {
                final tradeKey = UserProfile.trades.keys.elementAt(index);
                final trade = UserProfile.trades[tradeKey]!;
                final isSelected = _selectedTrade == tradeKey;

                return InkWell(
                  onTap: () => setState(() => _selectedTrade = tradeKey),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          trade['icon'] as String,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHindi
                              ? trade['nameHi'] as String
                              : trade['name'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage(ThemeData theme, bool isHindi) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(height: 24),
          Text(
            isHindi ? 'आप कहाँ रहते हैं?' : 'Where do you live?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? 'यह हमें आपके क्षेत्र की योजनाएँ खोजने में मदद करेगा'
                : 'This helps us find schemes for your area',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            initialValue: _selectedState.isEmpty ? null : _selectedState,
            decoration: InputDecoration(
              labelText: isHindi ? 'राज्य' : 'State',
              prefixIcon: const Icon(Icons.map),
              border: const OutlineInputBorder(),
            ),
            items: UserProfile.indianStates.map((state) {
              return DropdownMenuItem(value: state, child: Text(state));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedState = value);
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: isHindi ? 'जिला/शहर' : 'District/City',
              prefixIcon: const Icon(Icons.location_city),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _buildLanguagePage(ThemeData theme, bool isHindi) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.translate,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            isHindi ? 'कौन सी भाषा पसंद है?' : 'Which language do you prefer?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ...UserProfile.languages.entries.map((entry) {
            final isSelected = _selectedLanguage == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedLanguage = entry.key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value['nativeName']!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            entry.value['name']!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
