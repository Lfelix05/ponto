import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Classe auxiliar para gerenciar mensagens localizadas
class ValidatorMessages {
  static final ValidatorMessages _instance = ValidatorMessages._internal();
  factory ValidatorMessages() => _instance;
  ValidatorMessages._internal();

  // Mensagens em português (fallback)
  static const Map<String, String> _ptMessages = {
    'pleaseEnterEmail': 'Por favor, digite seu email',
    'enterValidEmail': 'Digite um email válido',
    'pleaseEnterPhone': 'Por favor, digite seu telefone',
    'enterValidPhone': 'Digite um telefone válido',
    'pleaseEnterPassword': 'Por favor, digite sua senha',
    'passwordMinLength': 'A senha deve ter pelo menos 6 caracteres',
    'pleaseConfirmPassword': 'Por favor, confirme sua senha',
    'passwordfail': 'As senhas não coincidem',
  };

  // Mensagens em inglês
  static const Map<String, String> _enMessages = {
    'pleaseEnterEmail': 'Please enter your email',
    'enterValidEmail': 'Enter a valid email',
    'pleaseEnterPhone': 'Please enter your phone number',
    'enterValidPhone': 'Enter a valid phone number',
    'pleaseEnterPassword': 'Please enter your password',
    'passwordMinLength': 'Password must be at least 6 characters long',
    'pleaseConfirmPassword': 'Please confirm your password',
    'passwordfail': 'Password do not match',
  };

  String _currentLocale = 'pt'; // Default locale
  bool _isInitialized = false;

  // Método estático para inicializar as mensagens de validação
  static Future<void> initialize() async {
    await ValidatorMessages()._init();
  }

  // Atualiza o locale quando o idioma é alterado
  static void updateLocale(String locale) {
    ValidatorMessages()._currentLocale = locale;
  }

  // Inicializa o locale atual
  Future<void> _init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLocale = prefs.getString('languageCode') ?? 'pt';
      _isInitialized = true;
    } catch (_) {
      _currentLocale = 'pt'; // Fallback
    }
  }

  // Obtém uma mensagem no idioma atual
  String getMessage(String key) {
    final messages = _currentLocale == 'en' ? _enMessages : _ptMessages;
    return messages[key] ?? _ptMessages[key] ?? key;
  }
}

class isAvalidEmail {
  static final _messages = ValidatorMessages();

  // Método que funciona mesmo sem contexto
  static String? validate(String? email) {
    // Como não podemos usar async/await diretamente, usamos os valores padrão
    if (email == null || email.isEmpty) {
      return _messages.getMessage('pleaseEnterEmail');
    }
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return _messages.getMessage('enterValidEmail');
    }
    return null;
  }

  // Novo método com internacionalização
  static String? validateWithContext(String? email, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (email == null || email.isEmpty) {
      return l10n.pleaseEnterEmail; // Retorna falso se o email estiver vazio
    }
    // expressão regular para validar um email
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return l10n.enterValidEmail; // Retorna falso se o email não for válido
    }
    return null;
  }
}

class isAvalidPhone {
  static final _messages = ValidatorMessages();

  // Método que funciona mesmo sem contexto
  static String? validate(String? phone) {
    if (phone == null || phone.isEmpty) {
      return _messages.getMessage('pleaseEnterPhone');
    }
    // expressão regular para validar um número de telefone
    final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return (phone.isEmpty || !phoneRegex.hasMatch(phone))
        ? _messages.getMessage('enterValidPhone')
        : null;
  }

  // Novo método com internacionalização
  static String? validateWithContext(String? phone, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (phone == null || phone.isEmpty) {
      return l10n.pleaseEnterPhone; // Retorna falso se o telefone estiver vazio
    }
    // expressão regular para validar um número de telefone
    final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return (phone.isEmpty || !phoneRegex.hasMatch(phone))
        ? l10n
            .enterValidPhone // Retorna falso se o telefone não for válido
        : null;
  }
}

class isAvalidPassword {
  static final _messages = ValidatorMessages();

  // Método que funciona mesmo sem contexto
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return _messages.getMessage('pleaseEnterPassword');
    }
    // Verifica se a senha tem pelo menos 6 caracteres
    if (password.length < 6) {
      return _messages.getMessage('passwordMinLength');
    }
    return null;
  }

  // Novo método com internacionalização
  static String? validateWithContext(String? password, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (password == null || password.isEmpty) {
      return l10n.pleaseEnterPassword; // Retorna falso se a senha estiver vazia
    }
    // Verifica se a senha tem pelo menos 6 caracteres
    if (password.length < 6) {
      return l10n.passwordMinLength; // Retorna falso se a senha for muito curta
    }
    return null;
  }
}

class confirmPassword {
  static final _messages = ValidatorMessages();

  // Método que funciona mesmo sem contexto
  static String? validate(String password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return _messages.getMessage('pleaseConfirmPassword');
    }
    if (password != confirmPassword) {
      return _messages.getMessage('passwordfail');
    }
    return null;
  }

  // Novo método com internacionalização
  static String? validateWithContext(
    String password,
    String? confirmPassword,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return l10n
          .pleaseConfirmPassword; // Retorna falso se a confirmação de senha estiver vazia
    }
    if (password != confirmPassword) {
      return l10n.passwordfail; // Retorna falso se as senhas não coincidirem
    }
    return null;
  }
}
