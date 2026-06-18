import 'dart:typed_data';

import 'package:eab/features/organization/data/picked_logo_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PickedLogoFile', () {
    test('lit extension depuis le nom du fichier', () {
      final file = PickedLogoFile(
        name: 'logo.EAB.PNG',
        bytes: Uint8List(0),
        mimeType: '',
      );

      expect(file.extension, 'png');
    });

    test('ignore les parametres dans le nom du fichier', () {
      final file = PickedLogoFile(
        name: 'logo.svg?download=1#preview',
        bytes: Uint8List(0),
        mimeType: '',
      );

      expect(file.extension, 'svg');
    });

    test('deduit extension depuis le type MIME quand le nom est incomplet', () {
      final file = PickedLogoFile(
        name: 'logo',
        bytes: Uint8List(0),
        mimeType: 'image/jpeg',
      );

      expect(file.extension, 'jpg');
    });
  });
}
