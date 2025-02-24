import 'dart:convert';

Venta ventaFromMap(String str) => Venta.fromMap(json.decode(str));

String ventaToMap(Venta data) => json.encode(data.toMap());

class Venta {
  final int? id;
  List<ProductoVenta> productos;
  double total;
  final String fecha;

  Venta({
    this.id,
    required this.productos,
    required this.total,
    required this.fecha,
  });

  factory Venta.fromMap(Map<String, dynamic> json) => Venta(
    id: json["id"],
    productos: List<ProductoVenta>.from(
      json["productos"].map((x) => ProductoVenta.fromMap(x)),
    ),
    total: json["total"],
    fecha: json["fecha"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "productos": List<dynamic>.from(productos.map((x) => x.toMap())),
    "total": total,
    "fecha": fecha,
  };
}

class ProductoVenta {
  final int productoId;
  int cantidad;
  double total;

  ProductoVenta({
    required this.productoId,
    required this.cantidad,
    required this.total,
  });

  factory ProductoVenta.fromMap(Map<String, dynamic> json) => ProductoVenta(
    productoId: json["producto_id"],
    cantidad: json["cantidad"],
    total: json["total"],
  );

  Map<String, dynamic> toMap() => {
    "producto_id": productoId,
    "cantidad": cantidad,
    "total": total,
  };
}
