import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/validator.dart';

class LocalizationProvider extends ChangeNotifier {
  Locale _locale = const Locale('pt');
  Locale get locale => _locale;

  LocalizationProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);

    _locale = locale;

    // Atualiza o idioma das mensagens de validação
    try {
      ValidatorMessages.updateLocale(locale.languageCode);
    } catch (_) {
      // Ignora erro se a classe ValidatorMessages não estiver disponível
    }

    notifyListeners();
  }
}
