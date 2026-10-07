import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/health_rules.dart';
import '../../../core/network/api_client.dart';
import '../data/log_repository.dart';
import '../domain/bowel_log.dart';
import '../../../core/storage/local_store.dart';

class LogEditorScreen extends ConsumerStatefulWidget {
  const LogEditorScreen({this.log, super.key});

  final BowelLog? log;

  @override
  ConsumerState<LogEditorScreen> createState() => _LogEditorScreenState();
}

class _LogEditorScreenState extends ConsumerState<LogEditorScreen> {
  final _note = TextEditingController();
  final _duration = TextEditingController();
  final _triggers = TextEditingController();
  int _type = 4;
  int _mood = 3;
  DateTime _loggedAt = DateTime.now();
  String? _volume;
  String? _color;
  final Set<String> _sensations = {};
  bool _details = false;
  bool _saving = false;

  static const _names = [
    'Si Batu Kerikil',
    'Sosis Bergelombang',
    'Pisang Retak',
    'Ular Idaman',
    'Gumpalan Santai',
    'Bubur Semangat',
    'Air Terjun',
  ];

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    if (log == null) return;
    _type = log.bristolType;
    _loggedAt = log.loggedAt;
    _volume = log.volume;
    _duration.text = log.durationMin?.toString() ?? '';
    _color = log.color;
    _sensations.addAll(log.sensations);
    _mood = log.mood ?? 3;
    _triggers.text = log.triggers.join(', ');
    _note.text = log.note ?? '';
    _details = true;
  }

  @override
  void dispose() {
    _note.dispose();
    _duration.dispose();
    _triggers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.log == null ? 'Catat jejak' : 'Ubah jejak'),
      actions: [
        TextButton(
          onPressed: () => setState(() => _details = !_details),
          child: Text(_details ? 'Ringkas' : 'Lengkapi'),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Bagaimana jejakmu?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Pilih tipe Bristol. Tidak ada foto yang perlu diunggah.'),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final type = index + 1;
              final selected = _type == type;
              return Semantics(
                button: true,
                selected: selected,
                label: 'Tipe $type, ${_names[index]}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _type = type),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$type',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            _names[index],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule_outlined),
            label: Text(
              'Waktu: ${MaterialLocalizations.of(context).formatShortDate(_loggedAt)}'
              ' · ${TimeOfDay.fromDateTime(_loggedAt).format(context)}',
            ),
          ),
          if (_details) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _volume,
              decoration: const InputDecoration(labelText: 'Volume'),
              items: const [
                DropdownMenuItem(value: 'sedikit', child: Text('Sedikit')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'banyak', child: Text('Banyak')),
              ],
              onChanged: (value) => setState(() => _volume = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _duration,
              decoration: const InputDecoration(
                labelText: 'Durasi (menit)',
                suffixText: 'menit',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _color,
              decoration: const InputDecoration(labelText: 'Warna'),
              items: const [
                DropdownMenuItem(
                  value: 'normal',
                  child: Text('Cokelat normal'),
                ),
                DropdownMenuItem(value: 'brown', child: Text('Cokelat')),
                DropdownMenuItem(value: 'red', child: Text('Merah / darah')),
                DropdownMenuItem(value: 'black', child: Text('Hitam pekat')),
                DropdownMenuItem(value: 'pale', child: Text('Pucat / putih')),
                DropdownMenuItem(value: 'yellow', child: Text('Kuning')),
                DropdownMenuItem(value: 'green', child: Text('Hijau')),
                DropdownMenuItem(value: 'other', child: Text('Lainnya')),
              ],
              onChanged: (value) => setState(() => _color = value),
            ),
            const SizedBox(height: 12),
            Text('Sensasi', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 4,
              children:
                  const [
                    ('tuntas', 'Tuntas'),
                    ('tidak_tuntas', 'Belum tuntas'),
                    ('nyeri', 'Nyeri'),
                    ('mengejan', 'Mengejan'),
                  ].map((item) {
                    return _SensationChip(
                      value: item.$1,
                      label: item.$2,
                      selectedValues: _sensations,
                      onChanged: (value) => setState(() {
                        if (value) {
                          _sensations.add(item.$1);
                        } else {
                          _sensations.remove(item.$1);
                        }
                      }),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),
            Text('Mood: $_mood / 5'),
            Slider(
              value: _mood.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_mood',
              onChanged: (value) => setState(() => _mood = value.round()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _triggers,
              decoration: const InputDecoration(
                labelText: 'Pemicu (pisahkan dengan koma)',
                hintText: 'Kopi, pedas, perjalanan',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 280,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : Text(_details ? 'Simpan jejak' : 'Simpan cepat'),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_loggedAt),
    );
    if (time == null) return;
    setState(() {
      _loggedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final duration = int.tryParse(_duration.text);
    if (duration != null && (duration < 0 || duration > 120)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durasi harus antara 0 dan 120 menit.')),
      );
      return;
    }

    setState(() => _saving = true);
    final existing = widget.log;
    final localId = existing?.id ?? createLocalId();
    final log = BowelLog(
      id: localId,
      clientId: existing?.clientId ?? localId,
      remoteId: existing?.remoteId,
      bristolType: _type,
      loggedAt: _loggedAt,
      volume: _details ? _volume : null,
      durationMin: _details ? duration : null,
      color: _details ? _color : null,
      sensations: _details ? _sensations.toList() : const [],
      mood: _details ? _mood : null,
      triggers: _details
          ? _triggers.text
                .split(',')
                .map((trigger) => trigger.trim())
                .where((trigger) => trigger.isNotEmpty)
                .take(20)
                .toList()
          : const [],
      note: _details && _note.text.trim().isNotEmpty ? _note.text.trim() : null,
      syncStatus: 'pending',
    );

    try {
      final result = await ref
          .read(logsProvider.notifier)
          .save(log, isNew: existing == null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.online
                ? 'Jejak tercatat dan tersinkron.'
                : 'Jejak tersimpan terenkripsi di perangkat, menunggu sinkron.',
          ),
        ),
      );
      final redFlags = detectRedFlags([
        RedFlagInput(
          loggedAt: log.loggedAt,
          bristolType: log.bristolType,
          color: log.color,
          severePain: log.sensations.contains('nyeri'),
        ),
      ]);
      if (redFlags.isNotEmpty) {
        await _showRedFlag(redFlags);
      }
      if (mounted) context.pop();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jejak tersimpan lokal, tetapi server menolak sinkronisasi: '
              '${error.message} (HTTP ${error.statusCode}).',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showRedFlag(List<RedFlagKind> redFlags) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.health_and_safety_outlined),
      title: const Text('Ada tanda yang perlu diperhatikan'),
      content: Text(
        '${redFlags.map(_redFlagMessage).join('\n\n')}\n\n'
        'JejakJamban bukan alat diagnosis.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Mengerti'),
        ),
      ],
    ),
  );

  String _redFlagMessage(RedFlagKind flag) => switch (flag) {
    RedFlagKind.blood =>
      'Warna merah/darah dapat memerlukan perhatian. Pertimbangkan '
          'konsultasi dengan tenaga kesehatan.',
    RedFlagKind.blackStool =>
      'Feses hitam pekat dapat memerlukan perhatian tenaga kesehatan.',
    RedFlagKind.paleStool =>
      'Warna pucat yang berulang dapat memerlukan pemeriksaan tenaga kesehatan.',
    RedFlagKind.severePain =>
      'Nyeri yang mengkhawatirkan sebaiknya dibicarakan dengan tenaga kesehatan.',
    RedFlagKind.persistentDiarrhea =>
      'Catatan tipe 6–7 selama lebih dari dua hari. Perhatikan hidrasi '
          'dan konsultasikan bila berlanjut.',
    RedFlagKind.persistentConstipation =>
      'Catatan tipe 1–2 selama lebih dari lima hari. Perhatikan asupan '
          'air/serat dan konsultasikan bila berlanjut.',
    RedFlagKind.patternChange =>
      'Perubahan pola lebih dari dua minggu patut dibicarakan dengan '
          'tenaga kesehatan.',
  };
}

class _SensationChip extends StatelessWidget {
  const _SensationChip({
    required this.value,
    required this.label,
    required this.selectedValues,
    required this.onChanged,
  });

  final String value;
  final String label;
  final Set<String> selectedValues;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selectedValues.contains(value),
    onSelected: onChanged,
  );
}
