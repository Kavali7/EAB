/// Design System — Thème principal EAB.
///
/// Version C1 : Google Fonts (Inter), tokens finalisés,
/// micro-animations, accessibilité (focus visible, contrastes).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════
// COULEURS
// ══════════════════════════════════════════════════════════════

class AppColors {
  // Principales
  static const Color primary = Color(0xFF0B2E4B);
  static const Color primaryLight = Color(0xFF1A4A6E);
  static const Color primaryDark = Color(0xFF061E33);
  static const Color secondary = Color(0xFFF2C94C);
  static const Color secondaryLight = Color(0xFFF5D778);
  static const Color accent = Color(0xFF3B82F6);

  // Neutres
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFAFBFC);
  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // États
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFEAB308);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Séparateurs & bordures
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderFocus = Color(0xFF3B82F6);

  // Overlay
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x0A000000);
}

// ══════════════════════════════════════════════════════════════
// TOKENS : SPACING, RADIUS, ELEVATION, ANIMATION
// ══════════════════════════════════════════════════════════════

// AppSpacing is defined in ui/theme/app_spacing.dart (canonical)
// Import via: import 'package:eab/ui/ui.dart';

class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
}

class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
  static const double high = 6;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pageTransition = Duration(milliseconds: 300);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutCubic;
}

// ══════════════════════════════════════════════════════════════
// ACCESSIBILITÉ
// ══════════════════════════════════════════════════════════════

class AppAccessibility {
  /// Zone cliquable minimum (WCAG 2.1 AA)
  static const double minTapTarget = 48;

  /// Épaisseur du focus ring
  static const double focusWidth = 2;

  /// Couleur du focus ring
  static const Color focusColor = AppColors.borderFocus;

  /// Décoration pour les éléments focusés
  static BoxDecoration get focusDecoration => BoxDecoration(
        border: Border.all(color: focusColor, width: focusWidth),
        borderRadius: AppRadius.mdAll,
      );
}

// ══════════════════════════════════════════════════════════════
// TEXT STYLES (avec Google Fonts Inter)
// ══════════════════════════════════════════════════════════════

class AppTextStyles {
  static TextStyle get _base => GoogleFonts.inter();

  static TextStyle get heading1 => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading2 => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading3 => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  // Legacy compat
  static TextStyle get title => heading3;
  static TextStyle get sectionTitle => heading3.copyWith(fontSize: 16);

  static TextStyle get subtitle => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // Legacy compat
  static TextStyle get secondary => bodySmall;

  static TextStyle get caption => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: AppColors.textTertiary,
      );

  static TextStyle get label => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppColors.textSecondary,
      );

  static TextStyle get buttonText => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );
}

// ══════════════════════════════════════════════════════════════
// THEME DATA
// ══════════════════════════════════════════════════════════════

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.interTextTheme().apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: textTheme,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      primaryContainer: AppColors.primaryLight,
      secondaryContainer: AppColors.secondaryLight,
    ),
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // ── FAB ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: AppElevation.medium,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
    ),

    // ── Boutons ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: AppElevation.low,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, AppAccessibility.minTapTarget),
        textStyle: AppTextStyles.buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, AppAccessibility.minTapTarget),
        textStyle: AppTextStyles.buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, AppAccessibility.minTapTarget),
        textStyle: AppTextStyles.buttonText,
      ),
    ),

    // ── Inputs ──
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: AppTextStyles.label,
      hintStyle: AppTextStyles.bodySmall,
      errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: AppColors.surface,
    ),

    // ── Cards ──
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: AppElevation.low,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),

    // ── TabBar ──
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: AppColors.secondary,
      labelStyle: AppTextStyles.subtitle,
      unselectedLabelStyle: AppTextStyles.body.copyWith(color: Colors.white70),
    ),

    // ── Divider ──
    dividerColor: AppColors.divider,
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
    ),

    // ── DataTable ──
    dataTableTheme: DataTableThemeData(
      headingTextStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
      dataTextStyle: AppTextStyles.body.copyWith(fontSize: 13),
      headingRowHeight: 44,
      dataRowMinHeight: 40,
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceElevated),
    ),

    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      elevation: AppElevation.medium,
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      elevation: AppElevation.high,
      titleTextStyle: AppTextStyles.heading3,
    ),

    // ── Chip ──
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      labelStyle: AppTextStyles.caption,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),

    // ── Scrollbar ──
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(
        AppColors.primary.withOpacity(0.4),
      ),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(6.0),
    ),

    // ── Transitions globales ──
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    // ── Tooltip ──
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: AppRadius.smAll,
      ),
      textStyle: AppTextStyles.caption.copyWith(color: Colors.white),
      waitDuration: const Duration(milliseconds: 500),
    ),

    // ── ListTile ──
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 8,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
    ),
  );
}

/// Compatibilité ascendante avec l'ancien thème.
class ChurchTheme {
  static const Color navy = AppColors.primary;
  static const Color gold = AppColors.secondary;
  static const Color slate = AppColors.textPrimary;
  static const Color cloud = AppColors.background;

  static ThemeData get lightTheme => buildAppTheme();
}
