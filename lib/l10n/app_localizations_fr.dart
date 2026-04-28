// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get loginWelcomeBack => 'Bon retour';

  @override
  String get loginSubtitle => 'Connectez-vous à votre compte DIDO';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailHint => 'votre@email.com';

  @override
  String get loginEmailRequired => 'L\'email est requis';

  @override
  String get loginEmailInvalid => 'Entrez un email valide';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginPasswordRequired => 'Le mot de passe est requis';

  @override
  String get loginPasswordMinLength => 'Minimum 6 caractères';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginSignInButton => 'Se connecter';

  @override
  String get loginOrSignInWith => 'Ou se connecter avec';

  @override
  String get loginNoAccountQuestion => 'Pas encore de compte ? ';

  @override
  String get loginSignUpLink => 'S\'inscrire';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsComingSoon => 'Bientôt disponible';
}
