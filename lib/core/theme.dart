import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _seed = Color(0xFF00897B);

ThemeData get lightTheme => _buildTheme(Brightness.light);

ThemeData get darkTheme => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
  );

  final surface = isDark ? const Color(0xFF101413) : const Color(0xFFF4F7F6);
  final surfaceContainer =
      isDark ? const Color(0xFF1A211F) : const Color(0xFFFFFFFF);
  final surfaceLow =
      isDark ? const Color(0xFF151B19) : const Color(0xFFECF2F0);

  final themedScheme = scheme.copyWith(
    surface: surface,
    surfaceContainerLowest: isDark ? const Color(0xFF0C100F) : surface,
    surfaceContainerLow: surfaceLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh:
        isDark ? const Color(0xFF222B28) : const Color(0xFFE4ECE9),
    surfaceContainerHighest:
        isDark ? const Color(0xFF2A3431) : const Color(0xFFD7E2DE),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: themedScheme,
    scaffoldBackgroundColor: surface,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: surface,
      foregroundColor: themedScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: surface,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: surface,
            ),
      titleTextStyle: TextStyle(
        color: themedScheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: themedScheme.onSurface),
      actionsIconTheme: IconThemeData(color: themedScheme.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: themedScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: themedScheme.onSurfaceVariant),
      prefixIconColor: themedScheme.onSurfaceVariant,
      suffixIconColor: themedScheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: themedScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: themedScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: themedScheme.error, width: 1.4),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: themedScheme.primary,
      foregroundColor: themedScheme.onPrimary,
      elevation: 2,
      focusElevation: 3,
      hoverElevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: themedScheme.inverseSurface,
      contentTextStyle: TextStyle(color: themedScheme.onInverseSurface),
      actionTextColor: themedScheme.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: themedScheme.outlineVariant.withValues(alpha: 0.5),
      space: 1,
      thickness: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: themedScheme.onSurfaceVariant,
      textColor: themedScheme.onSurface,
    ),
  );
}
