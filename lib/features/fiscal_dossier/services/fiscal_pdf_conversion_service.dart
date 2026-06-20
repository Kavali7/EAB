import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FiscalPdfConversionUnavailable implements Exception {
  const FiscalPdfConversionUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

class FiscalPdfConversionService {
  const FiscalPdfConversionService({required String converterUrl})
    : _converterUrl = converterUrl;

  final String _converterUrl;

  bool get isConfigured => _converterUrl.trim().isNotEmpty;

  Future<Uint8List> convertExcelToPdf({
    required Uint8List excelBytes,
    required String excelFilename,
  }) async {
    final baseUrl = _converterUrl.trim();
    if (baseUrl.isEmpty) {
      throw const FiscalPdfConversionUnavailable(
        'Export PDF officiel non configure : deployeez le service de conversion '
        'Excel vers PDF et renseignez FISCAL_PDF_CONVERTER_URL au build.',
      );
    }

    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token == null || token.isEmpty) {
      throw const FiscalPdfConversionUnavailable(
        'Export PDF officiel indisponible : session utilisateur introuvable.',
      );
    }

    final response = await http
        .post(
          _convertUri(baseUrl),
          headers: {
            'accept': 'application/pdf',
            'authorization': 'Bearer $token',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'filename': excelFilename,
            'xlsxBase64': base64Encode(excelBytes),
          }),
        )
        .timeout(const Duration(minutes: 2));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    throw StateError(_errorMessage(response));
  }

  Uri _convertUri(String baseUrl) {
    final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalized).resolve('convert');
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
      if (body is Map && body['error'] is String) {
        return body['error'] as String;
      }
    } catch (_) {
      // Le service peut retourner une erreur texte brute.
    }

    final body = response.body.trim();
    if (body.isNotEmpty) {
      return 'Conversion PDF refusee (${response.statusCode}) : $body';
    }
    return 'Conversion PDF refusee par le service (${response.statusCode}).';
  }
}
