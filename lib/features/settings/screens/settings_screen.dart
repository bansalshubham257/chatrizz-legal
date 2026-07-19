import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:chatrizz/app/theme/app_colors.dart';
import 'package:chatrizz/domain/entities/user.dart';
import 'package:chatrizz/features/settings/controllers/settings_controller.dart';
import 'package:chatrizz/features/settings/screens/privacy_policy_screen.dart';
import 'package:chatrizz/features/settings/screens/terms_of_service_screen.dart';
import 'package:chatrizz/features/auth/screens/auth_screen.dart';
import 'package:chatrizz/widgets/common/banner_ad_widget.dart';
import 'package:chatrizz/services/overlay_service.dart';
import 'package:chatrizz/services/ad_service.dart';
import 'package:chatrizz/services/api_service.dart';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (controller.isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildProfileCard(context, controller, colorScheme, textTheme),
            const SizedBox(height: 16),
            _buildMenuSection(context, controller, colorScheme, textTheme),
          ],
        ],
      ),
      bottomNavigationBar: BannerAdWidget(),
    );
  }

  Widget _buildProfileCard(BuildContext context, SettingsController controller, ColorScheme colorScheme, TextTheme textTheme) {
    final tier = controller.tier;
    final tierName = tier.name.toUpperCase();

    Color tierColor;
    switch (tier) {
      case SubscriptionTier.free:
        tierColor = colorScheme.onSurface.withValues(alpha: 0.6);
      case SubscriptionTier.plus:
        tierColor = AppColors.purpleLight;
      case SubscriptionTier.pro:
        tierColor = AppColors.warning;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tierName,
                style: TextStyle(
                  color: tierColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ChatRizz User',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (!controller.isFree)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.isPro ? 'All features unlocked!' : 'Ad-free experience',
                  style: TextStyle(color: AppColors.success, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, SettingsController controller, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      child: Column(
        children: [
          _menuTile(Icons.brightness_6_outlined, 'Theme', () {
            _showThemePicker(context, controller);
          }, trailing: Text(
            _getThemeModeLabel(controller.themeMode),
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ), colorScheme: colorScheme, textTheme: textTheme),
          const Divider(height: 0),
          _menuTile(Icons.language, 'Language', () {
            _showLanguagePicker(context);
          }, colorScheme: colorScheme, textTheme: textTheme),
          const Divider(height: 0),
          _menuTile(Icons.share_outlined, 'Share with Friends', () {
            Share.share(
              'Check out ChatRizz! The AI dating assistant that helps you nail your conversations. 🚀\n\nDownload it now!',
            );
          }, colorScheme: colorScheme, textTheme: textTheme),
          const Divider(height: 0),
          _buildOverlayTile(context, colorScheme, textTheme),
          const Divider(height: 0),
          _buildCategoryTile(context, colorScheme, textTheme),
          _menuTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            );
          }, colorScheme: colorScheme, textTheme: textTheme),
          const Divider(height: 0),
          _menuTile(Icons.description_outlined, 'Terms of Service', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
            );
          }, colorScheme: colorScheme, textTheme: textTheme),
          const Divider(height: 0),
          _menuTile(Icons.delete_forever_outlined, 'Delete Account', () {
            _showDeleteAccountDialog(context, colorScheme);
          }, colorScheme: colorScheme, textTheme: textTheme, iconColor: Colors.redAccent, titleColor: Colors.redAccent),
          const Divider(height: 0),
          _menuTile(Icons.logout, 'Sign Out', () {
            _showSignOutDialog(context, colorScheme);
          }, colorScheme: colorScheme, textTheme: textTheme, iconColor: Colors.orangeAccent, titleColor: Colors.orangeAccent),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemePicker(BuildContext context, SettingsController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Select Theme', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeOption(ctx, controller, ThemeMode.system, 'System', 'Follow device setting', colorScheme, textTheme),
            _themeOption(ctx, controller, ThemeMode.light, 'Light', 'Always light mode', colorScheme, textTheme),
            _themeOption(ctx, controller, ThemeMode.dark, 'Dark', 'Always dark mode', colorScheme, textTheme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext ctx,
    SettingsController controller,
    ThemeMode mode,
    String title,
    String subtitle,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return RadioListTile<ThemeMode>(
      title: Text(title, style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
      subtitle: Text(subtitle, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
      value: mode,
      groupValue: controller.themeMode,
      activeColor: AppColors.purple,
      onChanged: (value) {
        if (value != null) {
          controller.updateThemeMode(value);
          Navigator.pop(ctx);
        }
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final controller = context.read<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final languages = [
      'English',
      'Spanish',
      'French',
      'German',
      'Italian',
      'Portuguese',
      'Russian',
      'Chinese (Simplified)',
      'Japanese',
      'Korean',
      'Arabic',
      'Turkish',
      'Vietnamese',
      'Thai',
      'Indonesian',
      'Marathi',
      'Bangla',
      'Hindi',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Select Language', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (ctx, index) {
              final lang = languages[index];
              return ListTile(
                title: Text(lang, style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
                trailing: controller.language == lang
                    ? Icon(Icons.check, color: AppColors.purpleLight)
                    : null,
                onTap: () {
                  controller.updateLanguage(lang);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayTile(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final overlay = context.watch<OverlayService>();

    return ListTile(
      leading: Icon(Icons.brightness_1, color: overlay.isRunning ? AppColors.success : colorScheme.onSurface.withValues(alpha: 0.6), size: 24),
      title: Text('Floating Overlay', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
      subtitle: Text(
        overlay.isRunning ? 'Overlay active — tap bubble for AI suggestions' : 'Quick AI help while messaging',
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
      trailing: Switch(
        value: overlay.isRunning,
        activeColor: AppColors.purpleLight,
        onChanged: (value) async {
          if (value) {
            final granted = await overlay.checkPermission();
            if (!granted) {
              final proceed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: colorScheme.surface,
                  title: Text('Enable Floating Overlay', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
                  content: Text(
                    'ChatRizz needs "Display over other apps" permission to show a floating bubble.\n\n'
                    'This bubble lets you get AI reply suggestions without leaving your messaging app.\n\n'
                    'What the overlay does:\n'
                    '• Shows a small floating bubble you can drag anywhere\n'
                    '• ONLY activates when you manually tap the bubble\n'
                    '• Captures a screenshot of your current screen for OCR\n'
                    '• All processing happens on-device — no data is uploaded\n\n'
                    'The overlay does NOT:\n'
                    '• Monitor or record your screen activity\n'
                    '• Collect any personal information\n'
                    '• Modify or interfere with other apps\n\n'
                    'Next, you will also be asked for screen capture permission.',
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8)),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
                  ],
                ),
              );
              if (proceed != true) return;
              await overlay.requestPermission();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Grant overlay permission, then toggle on again.'), duration: Duration(seconds: 4)),
              );
              return;
            }
            final success = await overlay.start();
            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to start overlay. Check permissions.')),
              );
            }
          } else {
            await overlay.stop();
          }
        },
      ),
      onTap: () async {
        if (!overlay.isRunning) {
          final granted = await overlay.checkPermission();
          if (!granted) {
            await overlay.requestPermission();
            return;
          }
          await overlay.start();
        } else {
          await overlay.stop();
        }
      },
    );
  }

  Widget _buildCategoryTile(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final overlay = context.watch<OverlayService>();
    final cats = overlay.categories;

    return ListTile(
      leading: Icon(Icons.category_outlined, color: colorScheme.onSurface.withValues(alpha: 0.6)),
      title: Text('Reply Categories', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
      subtitle: Text(
        cats.join(', '),
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
      onTap: () => _showCategoryPicker(context),
    );
  }

  Future<void> _showCategoryPicker(BuildContext context) async {
    final overlay = context.read<OverlayService>();
    final ad = context.read<AdService>();
    final ds = context.read<LocalDataSource>();
    final currentCats = List<String>.from(overlay.categories);
    final tempCats = List<String>.from(currentCats);
    final colorScheme = Theme.of(context).colorScheme;

    const allCategories = ['Funny', 'Flirty', 'Bold', 'Savage', 'General', 'Corporate', 'Professional', 'Family', 'Friendly', 'Supportive', 'Romantic', 'Witty', 'Casual', 'Sarcastic'];

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Select Reply Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose up to 3 categories:', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8))),
                  const SizedBox(height: 12),
                  ...allCategories.map((cat) => CheckboxListTile(
                    title: Text(cat, style: TextStyle(color: colorScheme.onSurface)),
                    value: tempCats.contains(cat),
                    activeColor: AppColors.purpleLight,
                    checkColor: Colors.white,
                    onChanged: tempCats.contains(cat)
                        ? (val) {
                            if (val == true && tempCats.length >= 3) return;
                            setState(() {
                              if (val == true) tempCats.add(cat);
                              else tempCats.remove(cat);
                            });
                          }
                        : (val) {
                            if (tempCats.length >= 3) return;
                            setState(() {
                              tempCats.add(cat);
                            });
                          },
                  )),
                  if (tempCats.length >= 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Maximum 3 categories selected',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: tempCats.isEmpty || tempCats == currentCats ? null : () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (changed != true || tempCats.isEmpty || tempCats == currentCats) return;

    final adWatched = await ad.showRewardedAd();
    if (adWatched != true) return;

    overlay.setCategories(tempCats);
    final user = ds.getUser();
    if (user != null) {
      ds.saveUser(user.copyWith(categories: tempCats));
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Categories updated to: ${tempCats.join(", ")}')),
      );
    }
  }

  void _showSignOutDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text('Sign Out', style: TextStyle(color: Colors.orangeAccent)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = context.read<ApiService>();
              await api.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = context.read<ApiService>();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx2) => AlertDialog(
                  backgroundColor: colorScheme.surface,
                  title: const Text('Are you sure?', style: TextStyle(color: Colors.redAccent)),
                  content: const Text('All your chats, memories, and credits will be permanently erased.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx2, false), child: const Text('Keep Account')),
                    TextButton(onPressed: () => Navigator.pop(ctx2, true), child: const Text('Delete Forever', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              if (confirmed == true) {
                final ok = await api.deleteAccount();
                if (context.mounted) {
                  if (ok) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete account. Please try again.')),
                    );
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap, {Widget? trailing, Color? iconColor, Color? titleColor, required ColorScheme colorScheme, required TextTheme textTheme}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? colorScheme.onSurface.withValues(alpha: 0.7)),
      title: Text(title, style: textTheme.bodyLarge?.copyWith(color: titleColor ?? colorScheme.onSurface)),
      trailing: trailing ?? Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
      onTap: onTap,
    );
  }
}