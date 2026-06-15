// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const _authCallbackParams = {
  'access_token',
  'code',
  'error',
  'error_code',
  'error_description',
  'expires_at',
  'expires_in',
  'refresh_token',
  'state',
  'token_hash',
  'type',
};

void cleanAuthCallbackUrl() {
  final uri = Uri.base;
  if (!_authCallbackParams.any(uri.queryParameters.containsKey)) return;

  final cleanQuery = Map<String, String>.from(uri.queryParameters)
    ..removeWhere((key, _) => _authCallbackParams.contains(key));
  final cleanUri = uri.replace(
    queryParameters: cleanQuery.isEmpty ? null : cleanQuery,
  );
  final cleanPath =
      '${cleanUri.path}${cleanUri.hasQuery ? '?${cleanUri.query}' : ''}'
      '${cleanUri.hasFragment ? '#${cleanUri.fragment}' : ''}';

  html.window.history.replaceState(null, html.document.title, cleanPath);
}
