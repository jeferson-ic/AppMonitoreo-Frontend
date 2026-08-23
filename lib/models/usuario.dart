class Usuario {
  final String correo;
  final String nombre;
  final String rol;
  final String token;

  const Usuario({required this.correo, required this.nombre, required this.rol, required this.token});

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        correo: j['correo'] ?? '',
        nombre: j['nombre'] ?? '',
        rol: j['rol'] ?? 'USUARIO',
        token: j['token'] ?? '',
      );
}
