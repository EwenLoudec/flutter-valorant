import '../../../core/network/henrik_api_client.dart';

/// Turns whatever a request threw into a sentence worth showing.
String profileErrorText(Object error) {
  if (error is HenrikApiException) return error.message;
  return 'Impossible de récupérer ces données pour le moment.';
}
