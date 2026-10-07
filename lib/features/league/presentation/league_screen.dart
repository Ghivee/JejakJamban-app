import 'package:flutter/material.dart';

import '../../../core/widgets/info_card.dart';

class LeagueScreen extends StatelessWidget {
  const LeagueScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Liga')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        InfoCard(
          icon: Icons.emoji_events_outlined,
          title: 'Skor Jejak',
          child: Text(
            'Peringkat dirancang berdasarkan konsistensi, hidrasi, serat, '
            'misi, dan kontribusi komunitas—bukan jumlah BAB. Liga online '
            'belum diaktifkan pada MVP lokal ini.',
          ),
        ),
        SizedBox(height: 12),
        InfoCard(
          icon: Icons.lock_outline_rounded,
          title: 'Privasi tetap nomor satu',
          child: Text(
            'Log dan gejala kesehatan tidak pernah ditampilkan di '
            'leaderboard. Berbagi skor publik harus bersifat opt-in.',
          ),
        ),
      ],
    ),
  );
}
