import 'package:evalet/models/driver/session/checkin_request.dart';
import 'package:evalet/utils/whatsapp_qr_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The server's wording for current cards (card-scan-text.ts).
  String customerQr(String outletCode, int cardNumber) =>
      'https://wa.me/918885035945?text=${Uri.encodeComponent(
        "Hi ValetLink! I'd like my car when I'm ready. "
        'Outlet code: $outletCode. Card number: $cardNumber',
      )}';

  const oldQr =
      'https://wa.me/918885035945?text=Send%20to%20connect%20Card%20%2367%20at%20Cafe%20Niloufer';

  group('customer card QR', () {
    test('current card gives its Outlet Code and card number', () {
      final qr = customerQr('Orion East-2', 9);
      expect(tryParseOutletCodeFromWhatsAppUrl(qr), 'Orion East-2');
      expect(tryParseCardNumberFromWhatsAppUrl(qr), 9);
    });

    test('digits or "card" in the Outlet Code are not the card number', () {
      final qr = customerQr('Cardiff 42', 5);
      expect(tryParseOutletCodeFromWhatsAppUrl(qr), 'Cardiff 42');
      expect(tryParseCardNumberFromWhatsAppUrl(qr), 5);
    });

    test('older card has a card number but no Outlet Code', () {
      expect(tryParseCardNumberFromWhatsAppUrl(oldQr), 67);
      expect(tryParseOutletCodeFromWhatsAppUrl(oldQr), isNull);
    });
  });

  group('CheckinRequest', () {
    test('sends outletCode only when the card has one', () {
      expect(
        CheckinRequest(outletId: 2, cardNumber: 5, outletCode: 'OUT1').toJson(),
        {'outletId': 2, 'cardNumber': 5, 'outletCode': 'OUT1'},
      );
      expect(
        CheckinRequest(outletId: 2, cardNumber: 5).toJson(),
        {'outletId': 2, 'cardNumber': 5},
      );
    });
  });
}
