import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/health_rules.dart';
import '../../../core/widgets/info_card.dart';
import '../../log/data/log_repository.dart';

class InsightScreen extends ConsumerWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Insight')),
      body: logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Insight belum dapat dimuat: $error')),
        data: (items) {
          final counts = List<int>.filled(7, 0);
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          final recent = items.where((log) => log.loggedAt.isAfter(weekAgo));
          final redFlags = detectRedFlags(
            items.map(
              (log) => RedFlagInput(
                loggedAt: log.loggedAt,
                bristolType: log.bristolType,
                color: log.color,
                severePain: log.sensations.contains('nyeri'),
              ),
            ),
          );
          for (final log in recent) {
            counts[log.bristolType - 1]++;
          }
          final count = counts.fold<int>(0, (sum, value) => sum + value);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (redFlags.isNotEmpty) ...[
                InfoCard(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Ada tanda yang perlu diperhatikan',
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Text(redFlags.map(_redFlagMessage).join('\n\n')),
                ),
                const SizedBox(height: 12),
              ],
              InfoCard(
                icon: Icons.monitor_heart_outlined,
                title: 'Skor Kesehatan Pencernaan',
                child: Text(
                  count < 7
                      ? 'Kumpulkan catatan beberapa hari lagi agar pola '
                            'pribadimu lebih mudah dibaca.'
                      : 'Skor ringkas belum tersedia. Data di bawah hanya '
                            'merangkum catatan yang kamu simpan.',
                ),
              ),
              const SizedBox(height: 12),
              InfoCard(
                icon: Icons.bar_chart_rounded,
                title: 'Distribusi Bristol · 7 hari',
                child: count == 0
                    ? const Text(
                        'Belum ada catatan dalam 7 hari terakhir. '
                        'Grafik akan muncul setelah kamu mulai mencatat.',
                      )
                    : SizedBox(
                        height: 240,
                        child: Semantics(
                          label: 'Grafik distribusi tipe Bristol 1 sampai 7',
                          child: BarChart(
                            BarChartData(
                              maxY: (counts.reduce((a, b) => a > b ? a : b) + 1)
                                  .toDouble(),
                              barGroups: [
                                for (
                                  var index = 0;
                                  index < counts.length;
                                  index++
                                )
                                  BarChartGroupData(
                                    x: index + 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: counts[index].toDouble(),
                                        width: 18,
                                        borderRadius: BorderRadius.circular(6),
                                        color: index == 2 || index == 3
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                      ),
                                    ],
                                  ),
                              ],
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    interval: 1,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('${value.toInt()}'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              InfoCard(
                icon: Icons.calendar_month_outlined,
                title: 'Ringkasan',
                child: Text(
                  '$count jejak tercatat dalam 7 hari terakhir. '
                  'Frekuensi BAB berbeda pada setiap orang; angka ini '
                  'bukan penilaian kesehatan.',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'JejakJamban adalah alat pencatatan dan edukasi umum, '
                'bukan alat diagnosis. Konsultasikan gejala yang '
                'mengkhawatirkan dengan tenaga kesehatan.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }

  String _redFlagMessage(RedFlagKind flag) => switch (flag) {
    RedFlagKind.blood =>
      'Warna merah/darah dapat memerlukan perhatian. Pertimbangkan '
          'konsultasi dengan tenaga kesehatan.',
    RedFlagKind.blackStool =>
      'Feses hitam pekat yang bukan karena obat atau makanan dapat '
          'memerlukan perhatian tenaga kesehatan.',
    RedFlagKind.paleStool =>
      'Warna pucat berulang dapat memerlukan pemeriksaan tenaga kesehatan.',
    RedFlagKind.severePain =>
      'Nyeri saat BAB yang mengkhawatirkan sebaiknya dibicarakan dengan '
          'tenaga kesehatan.',
    RedFlagKind.persistentDiarrhea =>
      'Tipe 6–7 tercatat selama lebih dari dua hari. Perhatikan hidrasi '
          'dan konsultasikan bila berlanjut.',
    RedFlagKind.persistentConstipation =>
      'Tipe 1–2 tercatat selama lebih dari lima hari. Perhatikan asupan '
          'air/serat dan konsultasikan bila berlanjut.',
    RedFlagKind.patternChange =>
      'Perubahan pola yang berlangsung lebih dari dua minggu patut '
          'dibicarakan dengan tenaga kesehatan.',
  };
}
