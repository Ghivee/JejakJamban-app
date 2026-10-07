import 'package:flutter/material.dart';

import '../../../core/widgets/info_card.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Peta Jamban')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        InfoCard(
          icon: Icons.map_outlined,
          title: 'Peta komunitas',
          child: Text(
            'Peta toilet komunitas membutuhkan sumber data dan verifikasi '
            'lokasi. Fitur ini belum terhubung pada MVP, dan lokasi rumah '
            'atau kos tidak akan dipublikasikan.',
          ),
        ),
        SizedBox(height: 12),
        InfoCard(
          icon: Icons.privacy_tip_outlined,
          title: 'Berbagi lokasi itu pilihanmu',
          child: Text(
            'Izin lokasi tidak diminta saat aplikasi dibuka. Data lokasi '
            'tidak dikumpulkan pada MVP ini.',
          ),
        ),
      ],
    ),
  );
}
