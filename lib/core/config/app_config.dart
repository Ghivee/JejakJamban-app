class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static void validate() {
    const isRelease = bool.fromEnvironment('dart.vm.product');
    final baseUri = Uri.tryParse(apiBaseUrl);

    if (baseUri == null || !baseUri.hasAuthority) {
      throw StateError('API_BASE_URL harus berupa URL API yang valid.');
    }

    if (isRelease &&
        (baseUri.scheme != 'https' ||
            baseUri.host == 'localhost' ||
            baseUri.host == '10.0.2.2')) {
      throw StateError(
        'Build release wajib memakai URL HTTPS backend production melalui '
        '--dart-define=API_BASE_URL=https://.../api.',
      );
    }
  }
}
