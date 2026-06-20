import 'dart:typed_data';

import 'package:eab/features/fiscal_dossier/services/fiscal_pdf_conversion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refuse la conversion PDF officielle sans convertisseur configure', () {
    const service = FiscalPdfConversionService(converterUrl: '');

    expect(
      service.convertExcelToPdf(
        excelBytes: Uint8List.fromList([1, 2, 3]),
        excelFilename: 'dossier_fiscal.xlsx',
      ),
      throwsA(isA<FiscalPdfConversionUnavailable>()),
    );
  });
}
