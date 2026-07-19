import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatrizz/app/theme/app_colors.dart';
import 'package:chatrizz/core/constants/app_constants.dart';
import 'package:chatrizz/features/matches/controllers/match_list_controller.dart';
import 'package:chatrizz/features/matches/screens/match_detail_screen.dart';
import 'package:chatrizz/features/add_match/screens/add_match_screen.dart';
import 'package:chatrizz/services/ad_service.dart';
import 'package:chatrizz/widgets/common/credit_badge.dart';
import 'package:chatrizz/widgets/common/banner_ad_widget.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MatchListController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          CreditBadge(
            credits: controller.credits,
            onTap: () => _showCreditsDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () async {
          await context.read<AdService>().showInterstitialIfNeeded();
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddMatchScreen()),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _buildBody(context, controller, colorScheme, textTheme),
      bottomNavigationBar: BannerAdWidget(),
    );
  }

  Widget _buildBody(BuildContext context, MatchListController controller, ColorScheme colorScheme, TextTheme textTheme) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'No matches yet',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a match manually or import a screenshot\nto get started.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.matches.length,
        itemBuilder: (context, index) {
          final match = controller.matches[index];
          return Dismissible(
            key: Key(match.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.delete, color: colorScheme.onError),
            ),
            onDismissed: (direction) async {
              await controller.deleteMatch(match.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${match.name} deleted')),
              );
            },
            child: _MatchCard(match: match),
          );
        },
      ),
    );
  }
}

void _showCreditsDialog(BuildContext context) {
  final ctrl = context.read<MatchListController>();
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  showModalBottomSheet(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.auto_awesome, size: 40, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Credits',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have ${ctrl.credits} credits',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 4),
            Text(
              'Each AI reply costs 1 credit.',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await ctrl.watchAdForCredits();
                  if (!ctx.mounted) return;
                  if (result > 0) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Earned $result credits!')),
                    );
                  } else if (result < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${-result}/${AppConstants.rewardedAdsForTopUp} ads watched',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_circle_outline, size: 20),
                label: Text(
                  ctrl.pendingAdRewards > 0
                      ? 'Watch Ad (${ctrl.pendingAdRewards}/${AppConstants.rewardedAdsForTopUp})'
                      : 'Watch Ad for ${AppConstants.creditTopUpAmount} Credits',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
          ],
        ),
      );
    },
  );
}

class _MatchCard extends StatelessWidget {
  final dynamic match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await context.read<AdService>().showInterstitialIfNeeded();
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MatchDetailScreen(matchId: match.id),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  match.name.isNotEmpty ? match.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          match.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (match.age != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${match.age}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (match.lastMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        match.lastMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (match.lastActivityDate != null)
                Text(
                  _formatDate(match.lastActivityDate),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}