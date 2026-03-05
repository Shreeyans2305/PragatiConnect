import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../l10n/app_strings.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late String _selectedTrade;
  late String _selectedState;
  late String _selectedLanguage;
  late List<String> _secondaryTrades;
  late bool _whatsappOptIn;
  String? _profilePhotoPath;
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProvider>().profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _locationController = TextEditingController(text: profile?.location ?? '');
    _selectedTrade = profile?.primaryTrade ?? 'other';
    _selectedState = profile?.state ?? 'Maharashtra';
    _selectedLanguage = profile?.preferredLanguage ?? 'hi';
    _secondaryTrades = List<String>.from(profile?.secondaryTrades ?? []);
    _whatsappOptIn = profile?.whatsappOptIn ?? false;
    _profilePhotoPath = profile?.profilePhotoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final s = S.of(context);
    
    // Show bottom sheet with options
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                s.get('choose_photo'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: Text(s.get('choose_from_gallery')),
                subtitle: Text(s.get('select_existing_photo')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: Text(s.get('take_photo')),
                subtitle: Text(s.get('use_camera')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              if (_profilePhotoPath != null) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: Text(s.get('remove_photo')),
                  subtitle: Text(s.get('delete_current_photo')),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _profilePhotoPath = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Copy to app's documents directory for persistence
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_photo_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final savedPath = path.join(appDir.path, fileName);
        
        // Delete old photo if exists
        if (_profilePhotoPath != null) {
          final oldFile = File(_profilePhotoPath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }
        
        // Copy new photo
        await File(pickedFile.path).copy(savedPath);
        
        setState(() {
          _profilePhotoPath = savedPath;
        });
        
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.get('error_picking_image')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userProvider = context.read<UserProvider>();
      final authProvider = context.read<AuthProvider>();
      final hadPhotoBeforeButNowRemoved = 
          userProvider.profile?.profilePhotoPath != null && _profilePhotoPath == null;
      
      await userProvider.updateProfile(
        name: _nameController.text.trim(),
        profilePhotoPath: _profilePhotoPath,
        clearProfilePhoto: hadPhotoBeforeButNowRemoved,
        primaryTrade: _selectedTrade,
        secondaryTrades: _secondaryTrades,
        location: _locationController.text.trim(),
        state: _selectedState,
        preferredLanguage: _selectedLanguage,
        whatsappOptIn: _whatsappOptIn,
        authToken: authProvider.accessToken,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).get('profile_saved')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.grey.shade600;

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
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    s.get('save'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Builder(
                        builder: (context) {
                          final hasValidPhoto = _profilePhotoPath != null && 
                              File(_profilePhotoPath!).existsSync();
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                            backgroundImage: hasValidPhoto
                                ? FileImage(File(_profilePhotoPath!))
                                : null,
                            child: !hasValidPhoto
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  s.get('tap_to_change_photo'),
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              _SectionHeader(title: s.get('personal_info'), isDark: isDark),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: s.get('name'),
                  filled: true,
                  fillColor: cardColor,
                  prefixIcon: const Icon(Icons.person_outline),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s.get('required_field') : null,
                onChanged: (v) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: s.get('location'),
                  filled: true,
                  fillColor: cardColor,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s.get('required_field') : null,
              ),
              const SizedBox(height: 12),

              // State Dropdown
              DropdownButtonFormField<String>(
                value: _selectedState,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.get('state'),
                  filled: true,
                  fillColor: cardColor,
                  prefixIcon: const Icon(Icons.map_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                items: UserProfile.indianStates.map((state) {
                  return DropdownMenuItem(value: state, child: Text(state, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedState = v);
                },
              ),

              const SizedBox(height: 24),

              // Trade/Occupation
              _SectionHeader(title: s.get('occupation'), isDark: isDark),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedTrade,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.get('primary_trade'),
                  filled: true,
                  fillColor: cardColor,
                  prefixIcon: const Icon(Icons.work_outline),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                items: UserProfile.trades.entries.map((entry) {
                  final name = entry.value['name'] as String;
                  final icon = entry.value['icon'] as String;
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text('$icon $name', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTrade = v);
                },
              ),
              const SizedBox(height: 12),

              // Secondary Trades
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 20, color: subtitleColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.get('secondary_trades'),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: UserProfile.trades.entries
                          .where((e) => e.key != _selectedTrade)
                          .map((entry) {
                        final isSelected = _secondaryTrades.contains(entry.key);
                        return FilterChip(
                          label: Text(
                            '${entry.value['icon']} ${entry.value['name']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: isSelected,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _secondaryTrades.add(entry.key);
                              } else {
                                _secondaryTrades.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Language Preference
              _SectionHeader(title: s.get('language_preference'), isDark: isDark),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.get('preferred_language'),
                  filled: true,
                  fillColor: cardColor,
                  prefixIcon: const Icon(Icons.translate),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                items: UserProfile.languages.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      '${entry.value['nativeName']} (${entry.value['name']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedLanguage = v);
                },
              ),

              const SizedBox(height: 24),

              // WhatsApp Opt-In
              _SectionHeader(title: s.get('notifications'), isDark: isDark),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: SwitchListTile(
                  title: Text(s.get('whatsapp_updates')),
                  subtitle: Text(
                    s.get('whatsapp_updates_desc'),
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  value: _whatsappOptIn,
                  onChanged: (v) => setState(() => _whatsappOptIn = v),
                  secondary: const Icon(Icons.message_outlined),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
