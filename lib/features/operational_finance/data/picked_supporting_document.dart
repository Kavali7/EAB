import 'dart:typed_data';

class PickedSupportingDocument {
  const PickedSupportingDocument({
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

    return switch (contentType) {
      'application/pdf' => 'pdf',
      'image/png' => 'png',
      'image/jpeg' => 'jpg',
      'image/webp' => 'webp',
      _ => '',
    };
  }

  String get contentType {
    final cleanType = mimeType.toLowerCase().split(';').first.trim();
    if (cleanType.isNotEmpty) return cleanType;
    return switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }

  bool get isSupported {
    return const {'pdf', 'png', 'jpg', 'jpeg', 'webp'}.contains(extension);
  }
}
