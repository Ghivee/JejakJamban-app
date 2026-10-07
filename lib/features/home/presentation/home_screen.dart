import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/info_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../log/data/log_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      final session = next.asData?.value;
      final previousId = previous?.asData?.value?.id;
      if (session == null || session.id == previousId) return;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        try {
          final result = await ref.read(logsProvider.notifier).refresh();
          if (context.mounted && !result.online) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Belum terhubung. Catatan di perangkat tetap tersedia.',
                ),
              ),
            );
          }
        } on ApiException catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Sinkronisasi gagal: ${error.message} (HTTP ${error.statusCode}).',
                ),
              ),
            );
          }
        }
      });
    });
    final logs = ref.watch(logsProvider);
    final water = ref.watch(waterProvider);
    final checkIn = ref.watch(checkInProvider);
    final session = ref.watch(authProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JejakJamban',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: session == null ? 'Masuk atau daftar' : 'Akun',
            onPressed: () => context.push('/auth'),
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (session?.alias.characters.firstOrNull ?? 'J').toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(
          message: 'Catatan lokal belum dapat dibuka: $error',
          onRetry: () => ref.invalidate(logsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.read(logsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Halo, ${session?.alias ?? 'teman'}! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Catat. Pahami. Menang.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              if (session == null)
                const _OfflineNotice(
                  text:
                      'Mode tamu · catatan tersimpan terenkripsi di perangkat.',
                ),
              if (ref.watch(authProvider).hasError)
                _OfflineNotice(
                  text:
                      'Sesi akun belum dapat dibaca: '
                      '${ref.watch(authProvider).error}',
                  action: 'Masuk',
                  onPressed: () => context.push('/auth'),
                ),
              if (items.any((log) => log.syncStatus == 'pending'))
                _OfflineNotice(
                  text:
                      '${items.where((log) => log.syncStatus == 'pending').length} '
                      'jejak menunggu sinkronisasi.',
                  action: session == null ? 'Masuk' : 'Coba sinkron',
                  onPressed: session == null
                      ? () => context.push('/auth')
                      : () async {
                          final result = await ref
                              .read(logsProvider.notifier)
                              .refresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.online
                                      ? 'Sinkronisasi selesai.'
                                      : 'Belum terhubung. Catatan tetap aman di perangkat.',
                                ),
                              ),
                            );
                          }
                        },
                ),
              InfoCard(
                icon: Icons.local_fire_department_rounded,
                title: 'Rutinitas',
                child: checkIn.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) =>
                      Text('Rutinitas belum tersedia: $error'),
                  data: (summary) => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${summary.streak} hari',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            summary.checkedInToday
                                ? 'Check-in hari ini sudah tercatat.'
                                : 'Mulai dari check-in yang nyaman buatmu.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InfoCard(
                icon: Icons.water_drop_rounded,
                title: 'Air minum hari ini',
                child: water.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) =>
                      Text('Air belum tersedia: $error'),
                  data: (milliliters) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$milliliters / 2.000 ml',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (milliliters / 2000).clamp(0, 1).toDouble(),
                        minHeight: 9,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(waterProvider.notifier).addGlass(),
                        icon: const Icon(Icons.add),
                        label: const Text('+1 gelas · 250 ml'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InfoCard(
                icon: Icons.event_available_rounded,
                title: 'Check-in hari ini',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hari jurnal tidak harus berarti BAB setiap hari.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: checkIn.asData?.value.checkedInToday ?? false
                          ? null
                          : () => _showCheckIn(context, ref),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        checkIn.asData?.value.checkedInToday ?? false
                            ? 'Check-in selesai'
                            : 'Check-in hari ini',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InfoCard(
                icon: Icons.history_rounded,
                title: 'Ringkasan hari ini',
                child: logs.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) =>
                      const Text('Ringkasan belum bisa dimuat.'),
                  data: (values) {
                    final today = DateUtils.dateOnly(DateTime.now());
                    final count = values
                        .where(
                          (log) => DateUtils.isSameDay(log.loggedAt, today),
                        )
                        .length;
                    return Text(
                      '$count ${count == 1 ? 'jejak' : 'jejak'} tercatat hari ini.',
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const _MedicalDisclaimer(),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push('/catat'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Catat jejak'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCheckIn(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kabar hari ini?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final option in const [
                ('Sudah BAB', 'sudah'),
                ('Belum BAB hari ini', 'belum'),
                ('Hari ini diare', 'diare'),
                ('Hari ini sembelit', 'sembelit'),
              ])
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(option.$1),
                  onTap: () => Navigator.pop(context, option.$2),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await ref.read(checkInProvider.notifier).checkIn(result);
    }
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in dicatat. Kamu bisa mulai lagi kapan saja.'),
        ),
      );
    }
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.text, this.action, this.onPressed});

  final String text;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
        if (action != null)
          TextButton(onPressed: onPressed, child: Text(action!)),
      ],
    ),
  );
}

class _MedicalDisclaimer extends StatelessWidget {
  const _MedicalDisclaimer();

  @override
  Widget build(BuildContext context) => Text(
    'JejakJamban membantu mencatat dan memberi edukasi umum, bukan alat '
    'diagnosis atau pengganti nasihat tenaga kesehatan. Untuk gejala yang '
    'mengkhawatirkan, konsultasikan dengan dokter.',
    style: Theme.of(context).textTheme.bodySmall,
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    ),
  );
}
