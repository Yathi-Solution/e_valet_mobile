/// Matching form of an Outlet Code, as the server matches them: case-folded,
/// whitespace runs collapsed to one space.
String normalizeOutletCode(String code) {
  return code
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .toUpperCase()
      .toLowerCase();
}

/// True when the scanned card names an Outlet Code and it is not the code of
/// the outlet the driver is logged in at.
///
/// False when either code is unknown (an older card without one, or no
/// check-in has confirmed this outlet's code yet): the card then cannot be
/// judged on the device, and the server decides when the check-in reaches it.
bool isCardFromAnotherOutlet({
  required String? cardOutletCode,
  required String? currentOutletCode,
}) {
  final card = normalizeOutletCode(cardOutletCode ?? '');
  final current = normalizeOutletCode(currentOutletCode ?? '');
  if (card.isEmpty || current.isEmpty) return false;
  return card != current;
}
