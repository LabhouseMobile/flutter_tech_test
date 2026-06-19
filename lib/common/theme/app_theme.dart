import 'package:flutter/material.dart';

part 'colors.dart';
part 'text_styles.dart';

/// App-wide theming exposed as a [ThemeExtension] so widgets read semantic
/// colors via `Theme.of(context).extension<AppTheme>()!` instead of hard-coded
/// values.
class AppTheme extends ThemeExtension<AppTheme> {
  factory AppTheme({required bool isDark}) =>
      isDark ? AppTheme._dark() : AppTheme._light();

  const AppTheme._({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.foreground,
    required this.foregroundSoft,
    required this.error,
    required this.brightness,
  });

  factory AppTheme._light() => const AppTheme._(
    primary: AppColors.violet,
    onPrimary: AppColors.white,
    background: AppColors.white,
    surface: AppColors.paleGrey,
    foreground: AppColors.ink,
    foregroundSoft: AppColors.slate,
    error: AppColors.red,
    brightness: Brightness.light,
  );

  factory AppTheme._dark() => const AppTheme._(
    primary: AppColors.violetLight,
    onPrimary: AppColors.white,
    background: AppColors.night,
    surface: AppColors.nightSoft,
    foreground: AppColors.white,
    foregroundSoft: AppColors.fog,
    error: AppColors.red,
    brightness: Brightness.dark,
  );

  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color foreground;
  final Color foregroundSoft;
  final Color error;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  ThemeData toThemeData() {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
        error: error,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
      ),
      extensions: [this],
    );
  }

  @override
  AppTheme copyWith({
    Color? primary,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? foreground,
    Color? foregroundSoft,
    Color? error,
    Brightness? brightness,
  }) {
    return AppTheme._(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      foreground: foreground ?? this.foreground,
      foregroundSoft: foregroundSoft ?? this.foregroundSoft,
      error: error ?? this.error,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  AppTheme lerp(covariant AppTheme? other, double t) {
    if (other == null) return this;
    return AppTheme._(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      foregroundSoft: Color.lerp(foregroundSoft, other.foregroundSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

extension AppThemeX on BuildContext {
  AppTheme get appTheme => Theme.of(this).extension<AppTheme>()!;
}
