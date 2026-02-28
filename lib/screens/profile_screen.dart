import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/user_profile_provider.dart';
import '../l10n/app_strings.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfileProvider profileProvider;
  const ProfileScreen({super.key, required this.profileProvider});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfileProvider get _profile => widget.profileProvider;

  @override
  void initState() {
    super.initState();
    _profile.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  String _genderDisplayName(String genderKey) {
    final s = S.of(context);
    switch (genderKey) {
      case 'male':
        return s.get('male');
      case 'female':
        return s.get('female');
      case 'other':
        return s.get('other_gender');
      default:
        return s.get('not_set');
    }
  }

  /// Formats Aadhaar as "XXXX XXXX 1234" (last 4 visible).
  String _formatAadhaar(String aadhaar) {
    final digits = aadhaar.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return aadhaar;
    final last4 = digits.substring(digits.length - 4);
    return 'XXXX XXXX $last4';
  }

  /// Formats phone as "98765 43210" (all digits visible, spaced).
  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return phone;
    return '${digits.substring(0, 5)} ${digits.substring(5)}';
  }

  // ─── Profile Picture Picker ─────────────────────────────────────────────
  void _showProfilePicturePicker() async {
    HapticFeedback.lightImpact();
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        // Keep original quality — no compression or resizing
      );
      if (image == null || !mounted) return;

      final result = await Navigator.push<File?>(
        context,
        MaterialPageRoute(
          builder: (_) => _ImageCropPage(imageFile: File(image.path)),
        ),
      );
      if (result != null && mounted) {
        final appDir = await getApplicationDocumentsDirectory();
        final savedPath = '${appDir.path}/profile_picture.jpg';
        await result.copy(savedPath);
        await _profile.updateProfileImagePath(savedPath);
      }
    } catch (_) {
      // Fail silently
    }
  }

  // ─── Edit Profile Full-Page ─────────────────────────────────────────────
  void _openEditProfile() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _EditProfilePage(profile: _profile)),
    );
  }

  // ─── Account Actions ───────────────────────────────────────────────────
  void _confirmResetAccount() {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.get('reset_account'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          s.get('reset_confirm'),
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.get('cancel'),
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _profile.resetAccount();
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
            },
            child: Text(
              s.get('confirm'),
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFFF9F0A)
                    : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.get('delete_account'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          s.get('delete_confirm'),
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.get('cancel'),
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _profile.deleteAccount();
              Navigator.pop(ctx);
              Navigator.popUntil(context, (r) => r.isFirst);
              HapticFeedback.heavyImpact();
            },
            child: Text(
              s.get('delete_account'),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final primaryColor = isDark
        ? const Color(0xFF6AAFD4)
        : const Color(0xFF355872);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('profile')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ─── Profile Header ──────────────────────────────────────
            const SizedBox(height: 8),
            _buildAvatar(isDark, primaryColor),
            const SizedBox(height: 16),
            Text(
              _profile.displayName,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            if (_profile.occupation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _profile.occupation,
                style: TextStyle(
                  fontSize: 15,
                  color: subtitleColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ─── Edit Profile Button ─────────────────────────────────
            GestureDetector(
              onTap: _openEditProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      s.get('edit_profile'),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ─── Personal Info Section (read-only display) ───────────
            _SectionHeader(title: s.get('personal_info'), isDark: isDark),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    label: s.get('name'),
                    value: _profile.name.isNotEmpty
                        ? _profile.name
                        : s.get('not_set'),
                    isDark: isDark,
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _InfoTile(
                    icon: Icons.work_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: s.get('occupation'),
                    value: _profile.occupation.isNotEmpty
                        ? _profile.occupation
                        : s.get('not_set'),
                    isDark: isDark,
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _InfoTile(
                    icon: Icons.wc_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    label: s.get('gender'),
                    value: _profile.gender.isNotEmpty
                        ? _genderDisplayName(_profile.gender)
                        : s.get('not_set'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── Identity Info Section ───────────────────────────────
            _SectionHeader(title: s.get('read_only_info'), isDark: isDark),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.badge_rounded,
                    iconColor: const Color(0xFF10B981),
                    label: s.get('aadhaar_no'),
                    value: _profile.aadhaarNo.isNotEmpty
                        ? _formatAadhaar(_profile.aadhaarNo)
                        : s.get('not_set'),
                    isDark: isDark,
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _InfoTile(
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    label: s.get('phone_no'),
                    value: _profile.phoneNo.isNotEmpty
                        ? _formatPhone(_profile.phoneNo)
                        : s.get('not_set'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── Account Actions Section ─────────────────────────────
            _SectionHeader(title: s.get('account_actions'), isDark: isDark),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.refresh_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: s.get('reset_account'),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _confirmResetAccount();
                    },
                  ),
                  Divider(height: 1, indent: 60, color: borderColor),
                  _ActionTile(
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    label: s.get('delete_account'),
                    isDark: isDark,
                    isDestructive: true,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _confirmDeleteAccount();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark, Color primaryColor) {
    return GestureDetector(
      onTap: _showProfilePicturePicker,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF2C2C2E), const Color(0xFF3A3A3C)]
                    : [Colors.grey.shade100, Colors.grey.shade200],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: _profile.hasProfileImage
                  ? Image.file(
                      File(_profile.profileImagePath),
                      fit: BoxFit.cover,
                      width: 110,
                      height: 110,
                    )
                  : Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.grey.shade400,
                    ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF000000) : Colors.white,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Edit Profile Page — Apple Settings-style with all editable fields
// ═══════════════════════════════════════════════════════════════════════════════

class _EditProfilePage extends StatefulWidget {
  final UserProfileProvider profile;
  const _EditProfilePage({required this.profile});

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _aadhaarCtrl;
  late TextEditingController _phoneCtrl;
  late String _selectedGender;

  String? _aadhaarError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _occupationCtrl = TextEditingController(text: widget.profile.occupation);
    _aadhaarCtrl = TextEditingController(
      text: widget.profile.aadhaarNo.replaceAll(RegExp(r'\D'), ''),
    );
    _phoneCtrl = TextEditingController(
      text: widget.profile.phoneNo.replaceAll(RegExp(r'\D'), ''),
    );
    _selectedGender = widget.profile.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _occupationCtrl.dispose();
    _aadhaarCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final s = S.of(context);
    bool valid = true;

    // Aadhaar: if non-empty, must be exactly 12 digits
    final aadhaarDigits = _aadhaarCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (aadhaarDigits.isNotEmpty && aadhaarDigits.length != 12) {
      setState(() => _aadhaarError = s.get('invalid_aadhaar'));
      valid = false;
    } else {
      setState(() => _aadhaarError = null);
    }

    // Phone: if non-empty, must be exactly 10 digits
    final phoneDigits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.isNotEmpty && phoneDigits.length != 10) {
      setState(() => _phoneError = s.get('invalid_phone'));
      valid = false;
    } else {
      setState(() => _phoneError = null);
    }

    return valid;
  }

  Future<void> _save() async {
    if (!_validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();

    await widget.profile.updateName(_nameCtrl.text);
    await widget.profile.updateOccupation(_occupationCtrl.text);
    await widget.profile.updateGender(_selectedGender);

    final aadhaarDigits = _aadhaarCtrl.text.replaceAll(RegExp(r'\D'), '');
    await widget.profile.updateAadhaar(aadhaarDigits);

    final phoneDigits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    await widget.profile.updatePhone(phoneDigits);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final primaryColor = isDark
        ? const Color(0xFF6AAFD4)
        : const Color(0xFF355872);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.grey.shade500;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.get('edit_profile')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              s.get('save'),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Name & Occupation ───────────────────────────────────
              _SectionHeader(title: s.get('personal_info'), isDark: isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _EditField(
                      label: s.get('name'),
                      controller: _nameCtrl,
                      isDark: isDark,
                      labelColor: labelColor,
                    ),
                    Divider(height: 24, color: borderColor),
                    _EditField(
                      label: s.get('occupation'),
                      controller: _occupationCtrl,
                      isDark: isDark,
                      labelColor: labelColor,
                    ),
                    Divider(height: 24, color: borderColor),
                    // Gender selector
                    _GenderSelector(
                      label: s.get('gender'),
                      selectedGender: _selectedGender,
                      isDark: isDark,
                      labelColor: labelColor,
                      primaryColor: primaryColor,
                      onChanged: (g) => setState(() => _selectedGender = g),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Identity Info ──────────────────────────────────────
              _SectionHeader(title: s.get('read_only_info'), isDark: isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _EditField(
                      label: s.get('aadhaar_no'),
                      controller: _aadhaarCtrl,
                      isDark: isDark,
                      labelColor: labelColor,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      hintText: s.get('aadhaar_format'),
                      errorText: _aadhaarError,
                      onChanged: (_) {
                        if (_aadhaarError != null) {
                          setState(() => _aadhaarError = null);
                        }
                      },
                    ),
                    Divider(height: 24, color: borderColor),
                    _EditField(
                      label: s.get('phone_no'),
                      controller: _phoneCtrl,
                      isDark: isDark,
                      labelColor: labelColor,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      hintText: s.get('phone_format'),
                      errorText: _phoneError,
                      onChanged: (_) {
                        if (_phoneError != null) {
                          setState(() => _phoneError = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit Field Widget ────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final Color labelColor;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _EditField({
    required this.label,
    required this.controller,
    required this.isDark,
    required this.labelColor,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.hintText,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey.shade300,
              fontSize: 15,
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ─── Gender Selector ──────────────────────────────────────────────────────────

class _GenderSelector extends StatelessWidget {
  final String label;
  final String selectedGender;
  final bool isDark;
  final Color labelColor;
  final Color primaryColor;
  final ValueChanged<String> onChanged;

  const _GenderSelector({
    required this.label,
    required this.selectedGender,
    required this.isDark,
    required this.labelColor,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final options = [
      {'key': 'male', 'label': s.get('male')},
      {'key': 'female', 'label': s.get('female')},
      {'key': 'other', 'label': s.get('other_gender')},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: options.map((opt) {
            final isSelected = selectedGender == opt['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(opt['key'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.15)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Apple-style Image Crop Page — pinch-to-zoom, pan, gridlines, circular mask
// ═══════════════════════════════════════════════════════════════════════════════

class _ImageCropPage extends StatefulWidget {
  final File imageFile;
  const _ImageCropPage({required this.imageFile});

  @override
  State<_ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<_ImageCropPage>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  double _prevScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _prevOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  bool _showGrid = false;

  late AnimationController _gridFadeController;
  late Animation<double> _gridFadeAnim;

  @override
  void initState() {
    super.initState();
    _gridFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _gridFadeAnim = CurvedAnimation(
      parent: _gridFadeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _gridFadeController.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _prevScale = _scale;
    _prevOffset = _offset;
    _startFocalPoint = details.focalPoint;
    setState(() => _showGrid = true);
    _gridFadeController.forward();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_prevScale * details.scale).clamp(0.5, 5.0);
      // Proper pan: track actual focal point delta from start
      final delta = details.focalPoint - _startFocalPoint;
      _offset = _prevOffset + delta;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_scale < 1.0) {
      setState(() {
        _scale = 1.0;
        _offset = Offset.zero;
      });
    }
    _gridFadeController.reverse().then((_) {
      if (mounted) setState(() => _showGrid = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final primaryColor = isDark
        ? const Color(0xFF6AAFD4)
        : const Color(0xFF355872);
    final bgColor = isDark ? Colors.black : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, null);
          },
        ),
        title: Text(
          s.get('set_photo'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, widget.imageFile);
            },
            child: Text(
              s.get('save'),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportSize = min(
                    constraints.maxWidth - 40,
                    constraints.maxHeight - 40,
                  );

                  return SizedBox(
                    width: viewportSize,
                    height: viewportSize,
                    child: GestureDetector(
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      onScaleEnd: _onScaleEnd,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Image — pannable & zoomable inside clip
                          ClipOval(
                            child: SizedBox(
                              width: viewportSize,
                              height: viewportSize,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..translate(_offset.dx, _offset.dy, 0.0)
                                  ..scale(_scale),
                                child: Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.cover,
                                  width: viewportSize,
                                  height: viewportSize,
                                ),
                              ),
                            ),
                          ),

                          // Circular border
                          IgnorePointer(
                            child: Container(
                              width: viewportSize,
                              height: viewportSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          // Grid overlay during interaction
                          if (_showGrid)
                            IgnorePointer(
                              child: FadeTransition(
                                opacity: _gridFadeAnim,
                                child: _CropGridOverlay(size: viewportSize),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Hint
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 12),
              child: Text(
                s.get('pinch_zoom_hint'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid Overlay ─────────────────────────────────────────────────────────────

class _CropGridOverlay extends StatelessWidget {
  final double size;
  const _CropGridOverlay({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 0.5;

    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), paint);
    canvas.drawLine(
      Offset(thirdW * 2, 0),
      Offset(thirdW * 2, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), paint);
    canvas.drawLine(
      Offset(0, thirdH * 2),
      Offset(size.width, thirdH * 2),
      paint,
    );

    final center = Offset(size.width / 2, size.height / 2);
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(center.dx - 8, center.dy),
      Offset(center.dx + 8, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ─── Info Tile (read-only) ────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        color: _pressed
            ? (widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.isDestructive
                      ? Colors.red
                      : (widget.isDark ? Colors.white : Colors.black),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
