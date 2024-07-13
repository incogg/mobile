import 'dart:ui';

import 'package:chessground/chessground.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

CorePalette? _corePalette;

BoardColorScheme? _boardColorScheme;

/// Set the system core palette if available (android 12+ only).
///
/// It also defines the system board colors based on the core palette.
void setCorePalette(CorePalette? palette) {
  _corePalette = palette;

  if (palette != null) {
    final darkSquare = Color(palette.secondary.get(60));
    final lightSquare = Color(palette.primary.get(95));

    _boardColorScheme = BoardColorScheme(
      darkSquare: darkSquare,
      lightSquare: lightSquare,
      background: SolidColorBackground(
        lightSquare: lightSquare,
        darkSquare: darkSquare,
      ),
      whiteCoordBackground: SolidColorBackground(
        lightSquare: lightSquare,
        darkSquare: darkSquare,
        coordinates: true,
      ),
      blackCoordBackground: SolidColorBackground(
        lightSquare: lightSquare,
        darkSquare: darkSquare,
        coordinates: true,
        orientation: Side.black,
      ),
      lastMove: HighlightDetails(
        solidColor: Color(palette.tertiary.get(80)).withOpacity(0.6),
      ),
      selected: HighlightDetails(
        solidColor: Color(palette.neutral.get(40)).withOpacity(0.80),
      ),
      validMoves: Color(palette.neutral.get(40)).withOpacity(0.40),
      validPremoves: Color(palette.error.get(40)).withOpacity(0.30),
    );
  }
}

/// Get the core palette if available (android 12+ only).
CorePalette? getCorePalette() {
  return _corePalette;
}

/// Get the board colors based on the core palette, if available (android 12+).
BoardColorScheme? getBoardColorScheme() {
  return _boardColorScheme;
}
