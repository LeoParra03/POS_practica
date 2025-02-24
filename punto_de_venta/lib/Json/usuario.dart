import 'dart:convert';

Usuario usuarioFromMap(String str) => Usuario.fromMap(json.decode(str));

String usuarioToMap(Usuario data) => json.encode(data.toMap());

class Usuario {
  final int? id;
  final String nombre;
  final String password;
  final String? rol;

  Usuario({this.id, required this.nombre, required this.password, this.rol});

  factory Usuario.fromMap(Map<String, dynamic> json) => Usuario(
    id: json["id"],
    nombre: json["nombre"],
    password: json["password"],
    rol: json["rol"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "nombre": nombre,
    "password": password,
    "rol": rol,
  };
}
