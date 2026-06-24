import 'package:flutter_test/flutter_test.dart';

import 'package:eab/core/security/platform_owner_access.dart';

void main() {
  group('PlatformOwnerAccess', () {
    test('refuse un compte sans metadonnees proprietaire', () {
      expect(
        PlatformOwnerAccess.isOwnerIdentity(appMetadata: const {}),
        isFalse,
      );
    });

    test('accepte platform_owner dans app_metadata', () {
      expect(
        PlatformOwnerAccess.isOwnerIdentity(
          appMetadata: const {'platform_owner': true},
        ),
        isTrue,
      );
    });

    test('accepte role platform_owner dans app_metadata', () {
      expect(
        PlatformOwnerAccess.isOwnerIdentity(
          appMetadata: const {'role': 'platform_owner'},
        ),
        isTrue,
      );
    });

    test('ne confond pas admin national avec proprietaire plateforme', () {
      expect(
        PlatformOwnerAccess.isOwnerIdentity(
          appMetadata: const {'role': 'admin_national'},
        ),
        isFalse,
      );
    });
  });
}
