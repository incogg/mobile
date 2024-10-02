import 'dart:convert';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:lichess_mobile/src/binding.dart';
import 'package:lichess_mobile/src/db/secure_storage.dart';
import 'package:lichess_mobile/src/model/common/socket.dart';
import 'package:lichess_mobile/src/model/settings/preferences.dart' as pref;
import 'package:lichess_mobile/src/utils/color_palette.dart';
import 'package:lichess_mobile/src/utils/screen.dart';
import 'package:lichess_mobile/src/utils/string.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

final _logger = Logger('Init');

/// Run initialization tasks only once on first app launch or after an update.
Future<void> setupFirstLaunch() async {
  final prefs = LichessBinding.instance.sharedPreferences;
  final pInfo = await PackageInfo.fromPlatform();

  final appVersion = Version.parse(pInfo.version);
  final installedVersion = prefs.getString('installed_version');

  if (installedVersion == null ||
      Version.parse(installedVersion) != appVersion) {
    prefs.setString('installed_version', appVersion.canonicalizedVersion);
  }

  if (prefs.getBool('first_run') ?? true) {
    // Clear secure storage on first run because it is not deleted on app uninstall
    await SecureStorage.instance.deleteAll();

    await prefs.setBool('first_run', false);
  }

  // Generate a socket random identifier and store it for the app lifetime
  String? storedSri;
  try {
    storedSri = await SecureStorage.instance.read(key: kSRIStorageKey);
    if (storedSri == null) {
      final sri = genRandomString(12);
      _logger.info('Generated new SRI: $sri');
      await SecureStorage.instance.write(key: kSRIStorageKey, value: sri);
    }
  } on PlatformException catch (e) {
    _logger.severe('Could not get SRI from storage: $e');
    // Clear all secure storage if an error occurs because it probably means the key has
    // been lost
    await SecureStorage.instance.deleteAll();
  }
}

/// Display setup on Android.
///
/// This is meant to be called once during app initialization.
Future<void> androidDisplayInitialization(WidgetsBinding widgetsBinding) async {
  final prefs = LichessBinding.instance.sharedPreferences;

  // On android 12+ get core palette and set the board theme to system if it is not set
  try {
    await DynamicColorPlugin.getCorePalette().then((value) {
      setCorePalette(value);

      if (getCorePalette() != null &&
          prefs.getString(pref.Category.board.storageKey) == null) {
        prefs.setString(
          pref.Category.board.storageKey,
          jsonEncode(
            pref.Board.defaults.copyWith(boardTheme: pref.BoardTheme.system),
          ),
        );
      }
    });
  } catch (e) {
    _logger.fine('Device does not support core palette: $e');
  }

  // lock orientation to portrait on android phones
  final view = widgetsBinding.platformDispatcher.views.first;
  final data = MediaQueryData.fromView(view);
  if (data.size.shortestSide < FormFactor.tablet) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Sets edge-to-edge system UI mode on Android 12+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: true,
    ),
  );

  /// Enables high refresh rate for devices where it was previously disabled
  final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  final DisplayMode active = await FlutterDisplayMode.active;

  final List<DisplayMode> sameResolution = supported
      .where(
        (DisplayMode m) => m.width == active.width && m.height == active.height,
      )
      .toList()
    ..sort(
      (DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate),
    );

  final DisplayMode mostOptimalMode =
      sameResolution.isNotEmpty ? sameResolution.first : active;

  // This setting is per session.
  await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}