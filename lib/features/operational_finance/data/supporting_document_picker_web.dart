// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'picked_supporting_document.dart';

Future<PickedSupportingDocument?> pickSupportingDocument() {
  final completer = Completer<PickedSupportingDocument?>();
  final input = html.FileUploadInputElement()
    ..accept = 'application/pdf,image/png,image/jpeg,image/webp'
    ..multiple = false;

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Impossible de lire le fichier selectionne.'),
        );
      }
    });

    reader.onLoadEnd.first.then((_) {
      final bytes = _bytesFromReaderResult(reader.result);
      if (bytes == null) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Format de fichier illisible.'));
        }
        return;
      }

      if (!completer.isCompleted) {
        completer.complete(
          PickedSupportingDocument(
            name: file.name,
            bytes: bytes,
            mimeType: file.type,
          ),
        );
      }
    });

    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}

Uint8List? _bytesFromReaderResult(Object? result) {
  if (result is ByteBuffer) return Uint8List.view(result);
  if (result is Uint8List) return result;
  if (result is List<int>) return Uint8List.fromList(result);
  return null;
}
