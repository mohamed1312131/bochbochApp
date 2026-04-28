import 'package:flutter/widgets.dart';
import 'package:dido/l10n/app_localizations.dart';

/// Ergonomic accessor for translated strings.
///
/// Usage: context.l10n.loginWelcomeBack
/// Equivalent to: AppLocalizations.of(context).loginWelcomeBack
///
/// Locale is locked to French in v1 (see main.dart). When Arabic and
/// English ARB files are added in v1.x, no callsites need changes.
extension AppLocalizationsExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
