// @telos L1:function:lib/core/extensions:context_extensions

import 'package:flutter/material.dart';

/// Extensions on [BuildContext] for convenient access to common properties.
extension BuildContextExtensions on BuildContext {
  /// Returns the current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Returns the current [TextTheme].
  TextTheme get textTheme => theme.textTheme;

  /// Returns the current [ColorScheme].
  ColorScheme get colorScheme => theme.colorScheme;

  /// Returns the current [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Returns the current screen size.
  Size get screenSize => mediaQuery.size;

  /// Returns the current screen width.
  double get screenWidth => screenSize.width;

  /// Returns the current screen height.
  double get screenHeight => screenSize.height;

  /// Returns the current safe area padding.
  EdgeInsets get padding => mediaQuery.padding;

  /// Returns the current view insets (keyboard, etc.).
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// Returns whether the device is in landscape orientation.
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;

  /// Returns whether the device is in portrait orientation.
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;

  /// Returns whether dark mode is enabled.
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Returns the current device pixel ratio.
  double get devicePixelRatio => mediaQuery.devicePixelRatio;

  /// Returns whether the keyboard is visible.
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  /// Returns whether the device is a tablet (width >= 600).
  bool get isTablet => screenWidth >= 600;

  /// Returns whether the device is a phone (width < 600).
  bool get isPhone => screenWidth < 600;
}

/// Extensions on [BuildContext] for navigation.
extension NavigationExtensions on BuildContext {
  /// Pushes a named route.
  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Pops the current route.
  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// Pops until a specific route.
  void popUntil(RoutePredicate predicate) {
    Navigator.of(this).popUntil(predicate);
  }

  /// Pushes a route and removes all previous routes.
  Future<T?> pushNamedAndRemoveAll<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(
      this,
    ).pushNamedAndRemoveUntil<T>(routeName, (_) => false, arguments: arguments);
  }

  /// Returns whether the navigator can pop.
  bool get canPop => Navigator.of(this).canPop();
}

/// Extensions on [BuildContext] for showing snackbars.
extension SnackBarExtensions on BuildContext {
  /// Shows a snackbar with the given message.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration, action: action),
    );
  }

  /// Shows an error snackbar.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: colorScheme.error,
      ),
    );
  }

  /// Hides the current snackbar.
  void hideSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }
}
