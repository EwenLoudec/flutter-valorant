import 'package:flutter/material.dart';

/// Shown only when the app was built without its HenrikDev key: the key is
/// configuration, not something the player types.
class MissingApiKeyNotice extends StatelessWidget {
  const MissingApiKeyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2B90C).withValues(alpha: 0.10),
        border: Border.all(color: const Color(0xFFF2B90C).withValues(alpha: 0.6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.key_off_outlined, size: 18, color: Color(0xFFF2B90C)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cette version de l\'app a été compilée sans clé HenrikDev : le profil et le '
              'classement ne peuvent pas se charger. Mets la clé dans henrik.local.json, puis '
              'relance avec --dart-define-from-file=henrik.local.json.',
              style: TextStyle(fontSize: 12, height: 1.4, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
