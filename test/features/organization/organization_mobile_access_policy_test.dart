import 'package:flutter_test/flutter_test.dart';

import 'package:eab/features/organization/data/organization_model.dart';

void main() {
  Organization organizationWithParams(Map<String, dynamic>? parametres) {
    return Organization(
      id: 'org-1',
      nom: 'Eglise test',
      parametres: parametres,
    );
  }

  test('OrganizationMobileAccessPolicy autorise tout en mode complet', () {
    final policy = organizationWithParams(null).mobileAccessPolicy;

    expect(policy.isRestricted, isFalse);
    expect(policy.allowsRoute('/fiscal-dossiers'), isTrue);
    expect(policy.allowsRoute('/accounting-reports'), isTrue);
  });

  test(
    'OrganizationMobileAccessPolicy bloque les modules lourds sur mobile',
    () {
      final policy = organizationWithParams({
        OrganizationMobileAccessPolicy.paramKey: {
          'mode': OrganizationMobileAccessPolicy.modeRestricted,
        },
      }).mobileAccessPolicy;

      expect(policy.isRestricted, isTrue);
      expect(policy.allowsRoute('/members'), isTrue);
      expect(policy.allowsRoute('/organization-settings'), isTrue);
      expect(policy.blocksRoute('/fiscal-dossiers'), isTrue);
      expect(policy.blocksRoute('/accounting-reports'), isTrue);
    },
  );

  test(
    'OrganizationMobileAccessPolicy accepte les routes enfant autorisees',
    () {
      final policy = organizationWithParams({
        OrganizationMobileAccessPolicy.paramKey: {
          'mode': OrganizationMobileAccessPolicy.modeRestricted,
          'allowed_routes': ['/members'],
        },
      }).mobileAccessPolicy;

      expect(policy.allowsRoute('/members'), isTrue);
      expect(policy.allowsRoute('/members/detail-1'), isTrue);
      expect(policy.blocksRoute('/programs'), isTrue);
    },
  );
}
