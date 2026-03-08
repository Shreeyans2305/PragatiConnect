import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../config/environment.dart';

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
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedTrade = '';
  String _selectedState = '';
  String _selectedLanguage = 'hi';

  // Authentication state
  bool _otpSent = false;
  bool _isVerifying = false;
  bool _isSendingOtp = false;
  String? _authError;

  // Validation
  bool _emailValid = false;
  String? _emailError;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Send OTP to email
  Future<void> _sendOtp() async {
    if (!_emailValid) return;

    setState(() {
      _isSendingOtp = true;
      _authError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    
    final success = await authProvider.requestOtp(email);

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
      if (success) {
        _otpSent = true;
      } else {
        _authError = authProvider.errorMessage ?? 'Failed to send OTP';
      }
    });
  }

  /// Verify OTP and proceed
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _authError = 'Please enter 6-digit OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
      _authError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(otp);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      if (!success) {
        _authError = authProvider.errorMessage ?? 'Invalid OTP';
      }
    });

    if (!success) return;

    final userProvider = context.read<UserProvider>();
    final token = authProvider.accessToken;

    if (token != null && Environment.useBackendApi) {
      try {
        await userProvider
            .loadProfileFromBackend(token)
            .timeout(const Duration(seconds: 6), onTimeout: () => false);
      } catch (_) {
        // Do not block onboarding progression if profile fetch fails.
      }
      if (!mounted) return;

      if (userProvider.onboardingComplete) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
        return;
      }
    }

    // New/incomplete profile: proceed with details onboarding pages.
    _nextPage();
  }

  /// Check if we can proceed based on current page and auth state
  bool _canProceedFromEmail() {
    // If backend API is enabled, require OTP verification
    if (Environment.useBackendApi) {
      return _otpSent && context.read<AuthProvider>().isAuthenticated;
    }
    // Otherwise just validate email format
    return _emailValid;
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
        // For email page, check if authenticated (when using backend) or just valid email
        return _canProceedFromEmail();
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

  void _validateEmail(String value) {
    // Email validation
    final email = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    setState(() {
      if (email.isEmpty) {
        _emailValid = false;
        _emailError = null;
      } else if (!emailRegex.hasMatch(email)) {
        _emailValid = false;
        _emailError = 'Please enter a valid email address';
      } else {
        _emailValid = true;
        _emailError = null;
      }
    });
  }

  Future<void> _completeOnboarding() async {
    final userProvider = context.read<UserProvider>();
    final localeProvider = context.read<LocaleProvider>();
    final authProvider = context.read<AuthProvider>();

    final profile = UserProfile(
      email: _emailController.text.trim(),
      name: _nameController.text.isEmpty ? null : _nameController.text,
      primaryTrade: _selectedTrade,
      location: _locationController.text,
      state: _selectedState,
      preferredLanguage: _selectedLanguage,
    );

    await userProvider.saveProfile(profile, authToken: authProvider.accessToken);
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
    final authProvider = context.watch<AuthProvider>();
    final hideSkipButton = Environment.useBackendApi && authProvider.isAuthenticated;
    final showBottomNavigation =
        !Environment.useBackendApi || authProvider.isAuthenticated || _currentPage > 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (!hideSkipButton)
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
                  _buildEmailPage(theme, isHindi),
                  _buildNamePage(theme, isHindi),
                  _buildTradePage(theme, isHindi),
                  _buildLocationPage(theme, isHindi),
                  _buildLanguagePage(theme, isHindi),
                ],
              ),
            ),

            // Navigation buttons
            if (showBottomNavigation)
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
              )
            else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailPage(ThemeData theme, bool isHindi) {
    final useBackend = Environment.useBackendApi;
    
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
              _otpSent ? Icons.sms : Icons.email,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(height: 24),
          Text(
            _otpSent 
                ? (isHindi ? 'OTP दर्ज करें' : 'Enter OTP')
                : (isHindi ? 'अपना ईमेल पता दर्ज करें' : 'Enter your email address'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _otpSent
                ? (isHindi
                    ? '${_emailController.text} पर भेजा गया 6-अंकीय कोड दर्ज करें'
                    : 'Enter the 6-digit code sent to ${_emailController.text}')
                : (isHindi
                    ? 'हम आपकी प्रोफ़ाइल को आपके ईमेल से जोड़ेंगे'
                    : 'We\'ll link your profile to your email address'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          if (!_otpSent) ...[
            // Email input
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isSendingOtp,
              onChanged: _validateEmail,
              decoration: InputDecoration(
                labelText: isHindi ? 'ईमेल पता' : 'Email Address',
                prefixIcon: const Icon(Icons.email),
                errorText: _emailError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Send OTP button (only when using backend)
            if (useBackend && _emailValid) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSendingOtp ? null : _sendOtp,
                  child: _isSendingOtp
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isHindi ? 'OTP भेजें' : 'Send OTP'),
                ),
              ),
            ],
          ] else ...[
            // OTP input
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              enabled: !_isVerifying,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                letterSpacing: 8,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) => setState(() => _authError = null),
              decoration: InputDecoration(
                labelText: isHindi ? 'OTP कोड' : 'OTP Code',
                hintText: '• • • • • •',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Verify OTP button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isHindi ? 'सत्यापित करें' : 'Verify'),
              ),
            ),
            const SizedBox(height: 12),
            
            // Resend OTP / Change email
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _isVerifying ? null : () {
                    setState(() {
                      _otpSent = false;
                      _otpController.clear();
                      _authError = null;
                    });
                  },
                  child: Text(isHindi ? 'ईमेल बदलें' : 'Change Email'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _isVerifying || _isSendingOtp ? null : _sendOtp,
                  child: Text(isHindi ? 'OTP पुनः भेजें' : 'Resend OTP'),
                ),
              ],
            ),
          ],
          
          // Error message
          if (_authError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _authError!.toLowerCase().contains('otp')
                          ? 'Wrong OTP!'
                          : _authError!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Success message when authenticated
          if (context.watch<AuthProvider>().isAuthenticated && _otpSent) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHindi ? 'ईमेल सत्यापित!' : 'Email verified!',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
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
