final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

String? emailValidator(String? value) {
  if (value == null || value.isEmpty) return 'Email requerido';
  if (!_emailRegex.hasMatch(value)) return 'Email inválido';
  return null;
}

String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) return 'Contraseña requerida';
  if (value.length < 6) return 'Mínimo 6 caracteres';
  return null;
}
