
class isAvalidEmail {
  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return ("Por favor, digite seu email"); // Retorna falso se o email estiver vazio
    }
    // expressão regular para validar um email
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return ("Digite um email válido"); // Retorna falso se o email não for válido
    }
    return null;
  }
}

class isAvalidPhone {
  static String? validate(String? phone) {
    if (phone == null || phone.isEmpty) {
      return ("Por favor, digite seu telefone"); // Retorna falso se o telefone estiver vazio
    }
    // expressão regular para validar um número de telefone
    final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return (phone.isEmpty || !phoneRegex.hasMatch(phone))
        ? ("Digite um telefone válido") // Retorna falso se o telefone não for válido
        : null;
  }
}

class isAvalidPassword {
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return ("Por favor, digite sua senha"); // Retorna falso se a senha estiver vazia
    }
    // Verifica se a senha tem pelo menos 6 caracteres
    if (password.length < 6) {
      return ("A senha deve ter pelo menos 6 caracteres"); // Retorna falso se a senha for muito curta
    }
    return null;
  }
}

class confirmPassword {
  static String? validate(String password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return ("Por favor, confirme sua senha"); // Retorna falso se a confirmação de senha estiver vazia
    }
    if (password != confirmPassword) {
      return ("As senhas não coincidem"); // Retorna falso se as senhas não coincidirem
    }
    return null;
  }
}