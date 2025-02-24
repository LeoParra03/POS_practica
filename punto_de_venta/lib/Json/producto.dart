import 'dart:convert';

Producto productoFromMap(String str) => Producto.fromMap(json.decode(str));

String productoToMap(Producto data) => json.encode(data.toMap());

class Producto {
  final int? id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String sku;

  Producto({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.sku,
  });

  factory Producto.fromMap(Map<String, dynamic> json) => Producto(
    id: json["id"],
    nombre: json["nombre"],
    descripcion: json["descripcion"],
    precio: json["precio"],
    sku: json["sku"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "nombre": nombre,
    "descripcion": descripcion,
    "precio": precio,
    "sku": sku,
  };
}
