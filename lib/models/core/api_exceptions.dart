class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException(this.message, {this.statusCode, this.code});

  /// Short, user-friendly message suitable for SnackBars / error labels in the UI.
  /// For network issues we show a concise message instead of the full technical sentence.
  String get displayMessage {
    if (code == 'network_error') {
      return 'No internet. Check your connection.';
    }
    if (code == 'timeout') {
      return 'Connection timed out. Please try again.';
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}

/// True when [message] is a no-internet / connectivity failure (not shown as a toast).
bool isNetworkConnectivityMessage(String message) {
  const suppressed = {
    'No internet connection. Please check your network and try again.',
    'No internet. Check your connection.',
    'Connection timed out. Please try again.',
  };
  if (suppressed.contains(message)) return true;
  final lower = message.toLowerCase();
  return lower.startsWith('no internet') ||
      lower.contains('check your network');
}

/// Returns a clean, user-facing error string from any thrown object.
/// Prefers ApiException.displayMessage, strips common "Exception: " prefixes,
/// and never dumps the internal "ApiException(...)" wrapper into the UI.
String getDisplayErrorMessage(Object? error) {
  if (error is ApiException) {
    return error.displayMessage;
  }
  if (error is Exception) {
    final s = error.toString();
    if (s.startsWith('Exception: ')) {
      return s.substring('Exception: '.length);
    }
    // Avoid leaking "ApiException(..., ...)" style strings if someone passed the toString() result.
    if (s.startsWith('ApiException(')) {
      // Fall back to the raw message portion if it looks like our wrapper.
      final idx = s.lastIndexOf(', ');
      if (idx != -1 && idx + 2 < s.length) {
        return s.substring(idx + 2, s.length - 1);
      }
    }
    return s;
  }
  return error?.toString() ?? 'Something went wrong. Please try again.';
}
