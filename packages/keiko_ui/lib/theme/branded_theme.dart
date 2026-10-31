import "package:flutter/material.dart";
import "theme_constants.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      // Primary colors
      primary: BrandColors.primary500,
      surfaceTint: BrandColors.primary400,
      onPrimary: BrandColors.primary100,
      primaryContainer: BrandColors.primary300,
      onPrimaryContainer: BrandColors.primary900,
      // Secondary colors
      secondary: BrandColors.secondary500,
      onSecondary: BrandColors.secondary100,
      secondaryContainer: BrandColors.secondary300,
      onSecondaryContainer: BrandColors.secondary900,
      // Error colors
      error: BrandColors.error500,
      onError: BrandColors.error100,
      errorContainer: BrandColors.error300,
      onErrorContainer: BrandColors.error900,
      // Surface colors
      surface: BrandColors.primary100,
      onSurface: BrandColors.primary900,
      onSurfaceVariant: BrandColors.primary800,
      // Outline colors
      outline: BrandColors.primary400,
      outlineVariant: BrandColors.primary300,
      // Shadow and scrim
      shadow: BrandColors.primary900,
      scrim: BrandColors.primary900,
      // Inverse colors
      inverseSurface: BrandColors.primary800,
      onInverseSurface: BrandColors.primary100,
      inversePrimary: BrandColors.primary200,
      // Fixed colors
      primaryFixed: BrandColors.primary500,
      onPrimaryFixed: BrandColors.primary100,
      primaryFixedDim: BrandColors.primary400,
      onPrimaryFixedVariant: BrandColors.primary800,
      secondaryFixed: BrandColors.secondary500,
      onSecondaryFixed: BrandColors.secondary100,
      secondaryFixedDim: BrandColors.secondary400,
      onSecondaryFixedVariant: BrandColors.secondary800,
      // Surface containers
      surfaceDim: BrandColors.primary200,
      surfaceBright: BrandColors.primary100,
      surfaceContainerLowest: BrandColors.primary100,
      surfaceContainerLow: BrandColors.primary200,
      surfaceContainer: BrandColors.primary300,
      surfaceContainerHigh: BrandColors.primary400,
      surfaceContainerHighest: BrandColors.primary500,
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      // Primary colors
      primary: BrandColors.primary400,
      surfaceTint: BrandColors.primary500,
      onPrimary: BrandColors.primary900,
      primaryContainer: BrandColors.primary700,
      onPrimaryContainer: BrandColors.primary100,
      // Secondary colors
      secondary: BrandColors.secondary400,
      onSecondary: BrandColors.secondary900,
      secondaryContainer: BrandColors.secondary700,
      onSecondaryContainer: BrandColors.secondary100,
      // Error colors
      error: BrandColors.error400,
      onError: BrandColors.error900,
      errorContainer: BrandColors.error700,
      onErrorContainer: BrandColors.error100,
      // Surface colors
      surface: BrandColors.primary900,
      onSurface: BrandColors.primary100,
      onSurfaceVariant: BrandColors.primary200,
      // Outline colors
      outline: BrandColors.primary600,
      outlineVariant: BrandColors.primary700,
      // Shadow and scrim
      shadow: BrandColors.primary900,
      scrim: BrandColors.primary900,
      // Inverse colors
      inverseSurface: BrandColors.primary200,
      onInverseSurface: BrandColors.primary900,
      inversePrimary: BrandColors.primary800,
      // Fixed colors
      primaryFixed: BrandColors.primary400,
      onPrimaryFixed: BrandColors.primary900,
      primaryFixedDim: BrandColors.primary500,
      onPrimaryFixedVariant: BrandColors.primary200,
      secondaryFixed: BrandColors.secondary400,
      onSecondaryFixed: BrandColors.secondary900,
      secondaryFixedDim: BrandColors.secondary500,
      onSecondaryFixedVariant: BrandColors.secondary200,
      // Surface containers
      surfaceDim: BrandColors.primary800,
      surfaceBright: BrandColors.primary900,
      surfaceContainerLowest: BrandColors.primary900,
      surfaceContainerLow: BrandColors.primary800,
      surfaceContainer: BrandColors.primary700,
      surfaceContainerHigh: BrandColors.primary600,
      surfaceContainerHighest: BrandColors.primary500,
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,

        // Typography
        textTheme: TextTheme(
          // Display styles
          displayLarge: BrandTypography.headingBold,
          displayMedium: BrandTypography.headingMedium,
          displaySmall: BrandTypography.headingRegular,
          // Headline styles
          headlineLarge: BrandTypography.headingBold,
          headlineMedium: BrandTypography.headingMedium,
          headlineSmall: BrandTypography.headingRegular,
          // Title styles
          titleLarge: BrandTypography.headingMedium,
          titleMedium: BrandTypography.bodyMedium,
          titleSmall: BrandTypography.bodyRegular,
          // Body styles
          bodyLarge: BrandTypography.bodyRegular,
          bodyMedium: BrandTypography.bodyRegular,
          bodySmall: BrandTypography.bodySmall,
          // Label styles
          labelLarge: BrandTypography.label,
          labelMedium: BrandTypography.label,
          labelSmall: BrandTypography.label,
        ).apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),

        // Base colors
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: BrandTypography.headingMedium,
          toolbarTextStyle: BrandTypography.accentRegular,
        ),

        // Bottom Navigation Bar
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: colorScheme.surface,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurfaceVariant,
          selectedLabelStyle: BrandTypography.accentMedium,
          unselectedLabelStyle: BrandTypography.accentRegular,
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            textStyle: BrandTypography.accentMedium,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          elevation: 6,
        ),

        // Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.transparent,
          labelStyle: BrandTypography.accentRegular
              .copyWith(color: colorScheme.onSurfaceVariant),
          floatingLabelStyle: BrandTypography.accentRegular
              .copyWith(color: colorScheme.primary),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.error),
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: colorScheme.surface,
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        // Chips
        chipTheme: ChipThemeData(
          backgroundColor: colorScheme.surfaceContainerHighest,
          labelStyle: BrandTypography.accentRegular,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),

        // Data Tables
        dataTableTheme: DataTableThemeData(
          headingRowColor:
              WidgetStateProperty.all(colorScheme.surfaceContainerHighest),
          headingTextStyle: BrandTypography.accentMedium,
          dataTextStyle: BrandTypography.bodyRegular,
          dividerThickness: 1,
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: colorScheme.surface,
          elevation: 24,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      );

  List<ExtendedColor> get extendedColors => [
        // Add extended colors if needed
      ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
