import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../setup/providers/setup_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/currency_provider.dart';
import '../../security/providers/app_lock_provider.dart';
import '../../security/providers/privacy_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final int imageBytes = await image.length();
      final double fileSizeInMB = imageBytes / (1024 * 1024);
      if (fileSizeInMB > 5.0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imaginea este prea mare. Limita este de 5 MB (A ta are ${fileSizeInMB.toStringAsFixed(1)} MB).', style: GoogleFonts.manrope()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      setState(() { _isUploading = true; });

      dynamic imageFile;
      if (kIsWeb) {
        imageFile = await image.readAsBytes();
      } else {
        imageFile = File(image.path);
      }

      await firestoreService.uploadProfileImage(imageFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e', style: GoogleFonts.manrope())),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUploading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final userProfileStream = firestoreService.userProfileStream();

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: userProfileStream,
        builder: (context, snapshot) {
          final profileData = snapshot.data;
          final avatarUrl = profileData?['avatarUrl'] as String?;
          final displayName = profileData?['displayName'] ?? 'Expert User';
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null 
                          ? Icon(Icons.person, size: 60, color: Theme.of(context).primaryColor)
                          : null,
                      ),
                      if (_isUploading)
                        const CircularProgressIndicator(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt, size: 20, color: Theme.of(context).scaffoldBackgroundColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Name
              Center(
                child: Text(
                  displayName,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // My Financial Plan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Financial Plan', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {
                      ref.read(hasCompletedSetupProvider.notifier).completeSetup(); // Actually, to retake setup we need to clear it. But context.go('/setup') is enough.
                      context.push('/setup');
                    },
                    child: Text('Edit Plan', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final setupState = ref.watch(setupProvider);
                  final currency = ref.watch(currencyProvider);
                  return Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildPlanRow('Monthly Income', '$currency${setupState.monthlyIncome.toStringAsFixed(0)}'),
                          const Divider(height: 24),
                          _buildPlanRow('Auto-save Target', '${(setupState.savingsRate * 100).toInt()}%'),
                          const Divider(height: 24),
                          _buildPlanRow('Fixed Costs', '$currency${setupState.totalFixedCosts.toStringAsFixed(0)}'),
                          const Divider(height: 24),
                          _buildPlanRow('Free to Budget', '$currency${setupState.freeToBudget.toStringAsFixed(0)}', isBold: true, color: Theme.of(context).primaryColor),
                        ],
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 32),

              // Settings
              Text('Settings', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              
              // Theme Toggle
              Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Dark Mode', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                      secondary: const Icon(Icons.dark_mode),
                      value: themeMode == ThemeMode.dark,
                      activeThumbColor: Theme.of(context).primaryColor,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    ),
                    const Divider(height: 1),
                    Consumer(
                      builder: (context, ref, child) {
                        final isAppLockEnabled = ref.watch(appLockProvider.notifier).isAppLockEnabled();
                        return SwitchListTile(
                          title: Text('App Lock (Biometrics)', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                          secondary: const Icon(Icons.fingerprint),
                          value: isAppLockEnabled,
                          activeThumbColor: Theme.of(context).primaryColor,
                          onChanged: (val) {
                            ref.read(appLockProvider.notifier).toggleAppLock(val);
                          },
                        );
                      }
                    ),
                    const Divider(height: 1),
                    Consumer(
                      builder: (context, ref, child) {
                        final isPrivacyMode = ref.watch(privacyProvider);
                        return SwitchListTile(
                          title: Text('Privacy Mode', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                          subtitle: Text('Hide balances in public', style: GoogleFonts.manrope(fontSize: 12)),
                          secondary: const Icon(Icons.visibility_off),
                          value: isPrivacyMode,
                          activeThumbColor: Theme.of(context).primaryColor,
                          onChanged: (val) {
                            ref.read(privacyProvider.notifier).togglePrivacy();
                          },
                        );
                      }
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Currency Selection
              Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  title: Text('App Currency', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  leading: const Icon(Icons.payments_outlined),
                  trailing: Consumer(
                    builder: (context, ref, child) {
                      final currentCurrency = ref.watch(currencyProvider);
                      return DropdownButton<String>(
                        value: currentCurrency,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                        items: [
                          DropdownMenuItem(value: '\$', child: Text('USD (\$)', style: GoogleFonts.manrope())),
                          DropdownMenuItem(value: '€', child: Text('EURO (€)', style: GoogleFonts.manrope())),
                          DropdownMenuItem(value: 'RON', child: Text('RON', style: GoogleFonts.manrope())),
                          DropdownMenuItem(value: '£', child: Text('GBP (£)', style: GoogleFonts.manrope())),
                          DropdownMenuItem(value: 'A\$', child: Text('AUD (A\$)', style: GoogleFonts.manrope())),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(currencyProvider.notifier).setCurrency(val);
                          }
                        },
                      );
                    }
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Delete Account Button
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return AlertDialog(
                        title: Text('Delete Account', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.', style: GoogleFonts.manrope()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Cancel', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.onSurface)),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop(); // close dialog
                              try {
                                await ref.read(authControllerProvider.notifier).deleteAccount();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not delete account. Please log in again to verify your identity.', style: GoogleFonts.manrope()), backgroundColor: Theme.of(context).colorScheme.error),
                                  );
                                }
                              }
                            },
                            child: Text('Delete', style: GoogleFonts.manrope(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Account'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ].animate(interval: 50.ms).fade(duration: 400.ms, curve: Curves.easeOut).slideY(begin: 0.1, end: 0),
          );
        }
      ),
    );
  }

  Widget _buildPlanRow(String title, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
