import 'package:flutter/material.dart';
import 'package:punto_de_venta/Json/producto.dart';
import 'package:punto_de_venta/basedato_helper.dart';

class CrearProducto extends StatefulWidget {
  const CrearProducto({super.key});

  @override
  State<CrearProducto> createState() => _CrearProductoState();
}

class _CrearProductoState extends State<CrearProducto> {
  final titulo = TextEditingController();
  final detalle = TextEditingController();
  final precio = TextEditingController();
  final sku = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final db = BasedatoHelper();
  String? _skuError;

  Future<bool> validarSKU() async {
    List<Producto> productosExistentes = await db.buscarProducto(sku.text);
    return productosExistentes
        .isNotEmpty; // Retorna true si el SKU ya está en uso
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Producto"),
        actions: [
          IconButton(
            onPressed: () async {
              bool skuInUse = await validarSKU();
              if (skuInUse) {
                setState(() {
                  _skuError = 'El SKU ya está en uso';
                });
              } else {
                if (formKey.currentState!.validate()) {
                  double? precioValue = double.tryParse(precio.text);
                  if (precioValue == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('El precio debe ser un número válido'),
                      ),
                    );
                  } else {
                    db
                        .agregarProducto(
                          Producto(
                            nombre: titulo.text,
                            descripcion: detalle.text,
                            precio: precioValue,
                            sku: sku.text,
                          ),
                        )
                        .whenComplete(() {
                          Navigator.of(context).pop(true);
                        });
                  }
                }
              }
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              TextFormField(
                controller: titulo,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Requiere un título";
                  }
                  return null;
                },
                decoration: const InputDecoration(label: Text("Título")),
              ),
              TextFormField(
                controller: detalle,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Requiere detalles";
                  }
                  return null;
                },
                decoration: const InputDecoration(label: Text("Detalle")),
              ),
              TextFormField(
                controller: precio,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Requiere precio";
                  }
                  double? precioValue = double.tryParse(value);
                  if (precioValue == null) {
                    return 'Por favor ingresa un precio válido';
                  }
                  return null;
                },
                decoration: const InputDecoration(labelText: "Precio"),
              ),
              TextFormField(
                controller: sku,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Requiere SKU";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "SKU",
                  errorText: _skuError,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
