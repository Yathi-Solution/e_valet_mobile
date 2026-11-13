/// The message text a customer card QR carries: the `text` query parameter of
/// a WhatsApp share URL, or the input itself when it is already raw text.
String _whatsAppMessageText(String url) {
  String textToSearch = url.trim();
  // Only treat as URL if it looks like one (has scheme or wa.me or contains ?text=)
  if (url.contains('?') && (url.contains('text=') || url.contains('wa.me'))) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      // queryParameters is already decoded by Dart
      final textParam = uri.queryParameters['text'];
      if (textParam != null && textParam.isNotEmpty) {
        textToSearch = textParam;
      }
    }
  }
  // Decode in case of %23 for # in raw pasted/partial URL
  if (textToSearch.contains('%')) {
    try {
      textToSearch = Uri.decodeComponent(textToSearch);
    } catch (_) {}
  }
  return textToSearch;
}

/// Current card wording, written by the server:
/// `... Outlet code: <Outlet Code>. Card number: <n>`.
/// An Outlet Code has no full stop, so the first one ends it.
final RegExp _cardScan = RegExp(
  r'Outlet\s+code\s*:\s*([^.]+?)\s*\.\s*Card\s+number\s*:\s*(\d+)',
  caseSensitive: false,
);

/// Parses WhatsApp share URLs or raw message text and extracts the card number.
///
/// Supports:
/// - Current cards: `https://wa.me/<number>?text=...Outlet%20code%3A%20ABC.%20Card%20number%3A%2067`
/// - Older cards: https://wa.me/918885035945?text=Send%20to%20connect%20Card%20%2367%20at%20...
/// - Raw text: "Send to connect Card #67 at Cafe Niloufer Premium Lounge - Banjara Hills 👉"
/// Returns the card number (e.g. 67) or null if not found.
int? tryParseCardNumberFromWhatsAppUrl(String url) {
  if (url.isEmpty) return null;
  try {
    final textToSearch = _whatsAppMessageText(url);
    // Current wording first, so digits inside the Outlet Code are never
    // mistaken for the card number.
    final scan = _cardScan.firstMatch(textToSearch);
    if (scan != null) return int.tryParse(scan.group(2) ?? '');
    // Match "Card #67" – allow normal # or full-width ＃ (U+FF03), optional spaces
    RegExpMatch? match =
        RegExp(r'Card\s*[#＃]\s*(\d+)', caseSensitive: false)
            .firstMatch(textToSearch);
    if (match == null) {
      // Fallback: first digit sequence after "Card" (e.g. "Card No. 67", "Card 67")
      match = RegExp(r'Card\s*[^\d]*?(\d+)', caseSensitive: false)
          .firstMatch(textToSearch);
    }
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  } catch (_) {
    return null;
  }
}

/// The Outlet Code a customer card QR names, or null when it names none
/// (older printed cards carry only the card number and outlet name).
String? tryParseOutletCodeFromWhatsAppUrl(String url) {
  if (url.isEmpty) return null;
  try {
    final scan = _cardScan.firstMatch(_whatsAppMessageText(url));
    final code = scan?.group(1)?.trim() ?? '';
    return code.isEmpty ? null : code;
  } catch (_) {
    return null;
  }
}
