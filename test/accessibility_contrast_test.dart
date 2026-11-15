import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitabiyahe/ui/theme.dart';

double contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

void main() {
  test('helper text meets normal-text contrast on both light surfaces', () {
    for (final surface in [KitaColors.canvas, KitaColors.cream]) {
      expect(contrast(KitaColors.muted, surface), greaterThanOrEqualTo(4.5));
    }
  });
  test('secondary color role keeps readable normal text', () {
    final scheme = kitaTheme().colorScheme;
    expect(
      contrast(scheme.onSecondary, scheme.secondary),
      greaterThanOrEqualTo(4.5),
    );
  });
  test('primary and warning text meet normal-text contrast', () {
    expect(
      contrast(Colors.white, KitaColors.forest),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(KitaColors.warning, KitaColors.cream),
      greaterThanOrEqualTo(4.5),
    );
  });
}
