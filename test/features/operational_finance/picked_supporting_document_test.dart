import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:eab/features/operational_finance/data/picked_supporting_document.dart';

void main() {
  test('PickedSupportingDocument lit extension depuis le nom du fichier', () {
    final document = PickedSupportingDocument(
      name: 'facture-temple.PDF',
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'application/pdf',
    );

    expect(document.extension, 'pdf');
    expect(document.contentType, 'application/pdf');
    expect(document.isSupported, isTrue);
  });

  test('PickedSupportingDocument deduit JPG depuis le type MIME', () {
    final document = PickedSupportingDocument(
      name: 'photo',
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/jpeg',
    );

    expect(document.extension, 'jpg');
    expect(document.isSupported, isTrue);
  });

  test('PickedSupportingDocument refuse les formats non prevus', () {
    final document = PickedSupportingDocument(
      name: 'archive.zip',
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'application/zip',
    );

    expect(document.extension, 'zip');
    expect(document.isSupported, isFalse);
  });
}
