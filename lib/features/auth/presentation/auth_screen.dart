import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alias = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController();
  bool _registering = false;
  bool _healthConsent = false;
  bool _parentalConsent = false;

  @override
  void dispose() {
    _alias.dispose();
    _email.dispose();
    _password.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final session = auth.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun & privasi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (session case final user?) ...[
            CircleAvatar(
              radius: 32,
              child: Text(
                user.alias.characters.first.toUpperCase(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.alias,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(user.email, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const Text(
              'Catatan kesehatanmu tetap privat dan tidak ditampilkan di '
              'leaderboard.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: auth.isLoading ? null : _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ] else ...[
            Text(
              _registering ? 'Buat akun JejakJamban' : 'Masuk ke akunmu',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Atur alias, bukan nama asli. Tanpa akun, kamu tetap bisa '
              'mencatat secara lokal di perangkat ini.',
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_registering) ...[
                    TextFormField(
                      controller: _alias,
                      decoration: const InputDecoration(
                        labelText: 'Alias (3–20 karakter)',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Alias minimal 3 karakter.';
                        }
                        if (value.trim().length > 20 ||
                            !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
                          return 'Pakai huruf, angka, _ atau - (maks. 20).';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                        return 'Masukkan email yang valid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi (minimal 8 karakter)',
                    ),
                    obscureText: true,
                    textInputAction: _registering
                        ? TextInputAction.next
                        : TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Kata sandi minimal 8 karakter.';
                      }
                      return null;
                    },
                  ),
                  if (_registering) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _age,
                      decoration: const InputDecoration(labelText: 'Usia'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final age = int.tryParse(value ?? '');
                        if (age == null || age < 13 || age > 120) {
                          return 'Pendaftaran tersedia untuk usia 13 tahun ke atas.';
                        }
                        return null;
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _healthConsent,
                      onChanged: (value) =>
                          setState(() => _healthConsent = value ?? false),
                      title: const Text(
                        'Saya menyetujui pemrosesan catatan kesehatan untuk '
                        'menampilkan riwayat dan insight pribadi.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if ((int.tryParse(_age.text) ?? 18) <= 16)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _parentalConsent,
                        onChanged: (value) =>
                            setState(() => _parentalConsent = value ?? false),
                        title: const Text(
                          'Saya memiliki persetujuan orang tua/wali.',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                  ],
                  if (auth.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage(auth.error!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_registering ? 'Daftar' : 'Masuk'),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _registering = !_registering;
                _healthConsent = false;
                _parentalConsent = false;
              }),
              child: Text(
                _registering
                    ? 'Sudah punya akun? Masuk'
                    : 'Belum punya akun? Daftar',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'JejakJamban bukan alat diagnosis atau pengganti nasihat tenaga '
              'kesehatan profesional.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_registering && !_healthConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Persetujuan pemrosesan data kesehatan diperlukan.'),
        ),
      );
      return;
    }
    final age = int.tryParse(_age.text);
    if (_registering && age != null && age <= 16 && !_parentalConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Persetujuan orang tua/wali diperlukan.')),
      );
      return;
    }
    final controller = ref.read(authProvider.notifier);
    if (_registering) {
      await controller.register(
        alias: _alias.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        age: age!,
        healthConsent: _healthConsent,
        parentalConsent: _parentalConsent,
      );
    } else {
      await controller.login(_email.text.trim(), _password.text);
    }
  }

  Future<void> _logout() async {
    try {
      final revoked = await ref.read(authProvider.notifier).logout();
      if (!revoked && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sesi lokal diakhiri. Server offline; token server '
              'akan kedaluwarsa otomatis.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal keluar dari server: ${error.message}')),
        );
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 422) {
        final first = error.errors.values.firstOrNull;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      return '${error.message} (HTTP ${error.statusCode})';
    }
    return 'Tidak dapat terhubung ke server: $error';
  }
}
