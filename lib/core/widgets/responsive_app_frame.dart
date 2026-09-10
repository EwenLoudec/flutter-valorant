import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Keeps the app at a phone-like width on wide viewports (desktop browser,
/// tablet) instead of stretching mobile layouts edge-to-edge. Below
/// [breakpoint] it's a no-op so real phones render exactly as before.
class ResponsiveAppFrame extends StatelessWidget {
  const ResponsiveAppFrame({super.key, required this.child});

  final Widget child;

  static const double maxContentWidth = 480;
  static const double breakpoint = 560;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= breakpoint) return child;

        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: SizedBox(
              width: maxContentWidth,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border.symmetric(vertical: BorderSide(color: AppTheme.outlineDark)),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
