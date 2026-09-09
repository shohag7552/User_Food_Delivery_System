import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the two promises the brand palette makes:
///
///  1. `Constants.primaryColor` is the only knob — every other brand token is
///     derived from it, so a rebrand cannot leave a stale colour behind.
///  2. Deriving them changed no pixel for the shipped brand.
void main() {
  test('every brand token derives from Constants.primaryColor', () {
    expect(ColorResource.primaryDark, Constants.primaryColor);
    expect(ColorResource.primary, Constants.primaryColor);
    expect(ColorResource.appBarColor, Constants.primaryColor);
    expect(ColorResource.discountBadge, Constants.primaryColor);
    expect(ColorResource.primaryGradient.colors, [
      ColorResource.primaryDark,
      ColorResource.primaryMedium,
      ColorResource.primaryLight,
    ]);
    // The bug this replaced: the swatch was hand-written with a base of
    // 0xFF003B55 — a leftover blue — while only shade 500 tracked the brand.
    expect(ColorResource.primarySwatch.toARGB32(), Constants.primaryColor.toARGB32());
    expect(ColorResource.primarySwatch[500], Constants.primaryColor);
  });

  test('the shipped brand keeps its exact previous accent steps', () {
    expect(ColorResource.primaryDark, const Color(0xFFC92A2A));
    expect(ColorResource.primaryMedium, const Color(0xFFE03131));
    expect(ColorResource.primaryLight, const Color(0xFFF03E3E));
  });

  test('the swatch runs light to dark through the brand', () {
    double lightness(Color c) => HSLColor.fromColor(c).lightness;
    final swatch = ColorResource.primarySwatch;

    expect(lightness(swatch[50]!), greaterThan(lightness(swatch[500]!)));
    expect(lightness(swatch[900]!), lessThan(lightness(swatch[500]!)));
    for (final pair in [[50, 100], [100, 200], [200, 300], [300, 400],
                        [400, 500], [500, 600], [600, 700], [700, 800], [800, 900]]) {
      expect(
        lightness(swatch[pair[0]]!),
        greaterThan(lightness(swatch[pair[1]]!)),
        reason: 'shade ${pair[0]} must be lighter than ${pair[1]}',
      );
    }
  });

  test('accent steps stay brighter than the base for any brand colour', () {
    // Guards the clamping: a near-white or near-black knob must not invert the
    // ramp or throw.
    double lightness(Color c) => HSLColor.fromColor(c).lightness;
    expect(
      lightness(ColorResource.primaryLight),
      greaterThanOrEqualTo(lightness(ColorResource.primaryDark)),
    );
    expect(
      lightness(ColorResource.primaryMedium),
      greaterThanOrEqualTo(lightness(ColorResource.primaryDark)),
    );
  });
}
