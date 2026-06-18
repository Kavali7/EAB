import 'dart:typed_data';

class PickedLogoFile {
  const PickedLogoFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;

  String get extension {
    final cleanName = name.split('?').first.split('#').first;
    final index = cleanName.lastIndexOf('.');
    if (index != -1 && index < cleanName.length - 1) {
      return cleanName.substring(index + 1).toLowerCase();
    }

    return switch (mimeType.toLowerCase().split(';').first.trim()) {
      'image/png' => 'png',
      'image/jpeg' => 'jpg',
      'image/webp' => 'webp',
      'image/svg+xml' => 'svg',
      _ => '',
    };
  }
}
