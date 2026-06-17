import 'dart:typed_data';

Future<void> downloadBytes({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) {
  throw UnsupportedError(
    'Le telechargement de fichier est disponible dans la version web.',
  );
}
