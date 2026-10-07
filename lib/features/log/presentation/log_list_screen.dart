import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/info_card.dart';
import '../data/log_repository.dart';
import '../domain/bowel_log.dart';

class LogListScreen extends ConsumerWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jejakku'),
        actions: [
          IconButton(
            tooltip: 'Sinkronkan',
            onPressed: () => _sync(context, ref),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/catat'),
        icon: const Icon(Icons.add),
        label: const Text('Catat jejak'),
      ),
      body: logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Riwayat belum dapat dimuat: $error'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 80),
                InfoCard(
                  icon: Icons.edit_note_rounded,
                  title: 'Belum ada jejak',
                  child: Text('Catat yang pertama, kapan pun kamu siap.'),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(logsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _LogTile(log: items[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(logsProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.online
                  ? 'Catatan sudah tersinkron.'
                  : 'Offline atau belum masuk. Catatan tersimpan di perangkat.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sinkronisasi ditolak: ${error.message} '
              '(HTTP ${error.statusCode})',
            ),
          ),
        );
      }
    }
  }
}

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.log});

  final BowelLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _typeColor(context, log.bristolType),
          child: Text(
            '${log.bristolType}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Tipe ${log.bristolType} · ${_label(log.bristolType)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${MaterialLocalizations.of(context).formatShortDate(log.loggedAt)}'
          ' · ${TimeOfDay.fromDateTime(log.loggedAt).format(context)}'
          '${log.syncStatus == 'pending' ? ' · Menunggu sinkron' : ''}'
          '${log.note == null || log.note!.isEmpty ? '' : '\n${log.note}'}',
        ),
        isThreeLine: log.note?.isNotEmpty ?? false,
        trailing: PopupMenuButton<String>(
          tooltip: 'Aksi jejak',
          onSelected: (value) async {
            if (value == 'edit') {
              await context.push('/catat', extra: log);
            } else {
              await _confirmDelete(context, ref);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Ubah')),
            PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
        onTap: () => context.push('/catat', extra: log),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jejak?'),
        content: const Text('Catatan ini akan dihapus dari riwayatmu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await ref.read(logsProvider.notifier).remove(log);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.online || log.remoteId == null
                  ? 'Jejak dihapus.'
                  : 'Penghapusan tersimpan dan menunggu sinkron.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server menolak penghapusan: ${error.message}'),
          ),
        );
      }
    }
  }

  static String _label(int type) => const [
    'Si Batu Kerikil',
    'Sosis Bergelombang',
    'Pisang Retak',
    'Ular Idaman',
    'Gumpalan Santai',
    'Bubur Semangat',
    'Air Terjun',
  ][type - 1];

  static Color _typeColor(BuildContext context, int type) {
    if (type <= 2) return const Color(0xFFD7B48A);
    if (type <= 4) return Theme.of(context).colorScheme.primaryContainer;
    if (type == 5) return const Color(0xFFFFCF85);
    return const Color(0xFFFFA270);
  }
}
