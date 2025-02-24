import 'package:flutter/material.dart';
import 'package:punto_de_venta/Json/producto.dart';
import 'package:punto_de_venta/Json/venta.dart';
import 'package:punto_de_venta/basedato_helper.dart';
import 'package:punto_de_venta/pages/crear_producto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:csv/csv.dart';

class GestionProductos extends StatefulWidget {
  static String id = 'GestionProductos_screen';
  _GestionProductosState createState() => _GestionProductosState();
}

class _GestionProductosState extends State<GestionProductos> {
  late BasedatoHelper dbHelper;
  final nombre = TextEditingController();
  final detalle = TextEditingController();
  final precio = TextEditingController();
  final sku = TextEditingController();
  final palabraclave = TextEditingController();

  late Future<List<Producto>> productos;
  late Future<List<Venta>> ventas;

  @override
  void initState() {
    super.initState();
    dbHelper = BasedatoHelper();
    productos = dbHelper.obtenerProductos();
    ventas = dbHelper.obtenerVentas();
  }

  Future<List<Producto>> obtenerTodoProductos() {
    return dbHelper.obtenerProductos();
  }

  Future<List<Producto>> buscarProducto() {
    return dbHelper.buscarProducto(palabraclave.text);
  }

  Future<void> generarCSVProductos() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permisos de almacenamiento no concedidos")),
        );
        return;
      }
    }
    Directory directory;
    if (Platform.isAndroid) {
      directory =
          await getExternalStorageDirectory() ??
          Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = Directory('/storage/emulated/0/Download');
    }

    final path = '${directory.path}/productos.csv';

    List<Producto> productosData = await dbHelper.obtenerProductos();
    List<List<String>> csvData = [
      ['SKU', 'Nombre', 'Descripcion', 'Precio'],
    ];

    for (var producto in productosData) {
      csvData.add([
        producto.sku,
        producto.nombre,
        producto.descripcion,
        '\$${producto.precio.toStringAsFixed(2)}', // Precio
      ]);
    }
    String csvString = const ListToCsvConverter().convert(csvData);
    final file = File(path);
    await file.writeAsString(csvString);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("CSV exportado exitosamente a: $path")),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      productos = obtenerTodoProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearProducto()),
          ).then((value) {
            if (value) {
              _refresh();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: palabraclave,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    productos = buscarProducto();
                  });
                } else {
                  setState(() {
                    productos = obtenerTodoProductos();
                  });
                }
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                icon: Icon(Icons.search),
                hintText: "Buscar",
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Producto>>(
              future: productos,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<Producto>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No se encontraron productos"),
                  );
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                } else {
                  final items = snapshot.data ?? <Producto>[];
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            items[index].nombre.isNotEmpty
                                ? items[index].nombre[0]
                                : '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[index].nombre,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              items[index].descripcion,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "\$${items[index].precio.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Confirmar Eliminación"),
                                      content: Text(
                                        "¿Estás seguro de que deseas eliminar este producto?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            dbHelper
                                                .eliminarProducto(
                                                  items[index].id!,
                                                )
                                                .whenComplete(() {
                                                  _refresh();
                                                  Navigator.pop(context);
                                                });
                                          },
                                          child: const Text("Sí, eliminar"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("No, cancelar"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            nombre.text = items[index].nombre;
                            detalle.text = items[index].descripcion;
                            precio.text = items[index].precio.toString();
                            sku.text = items[index].sku;
                          });
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                actions: [
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          dbHelper.buscarProducto(sku.text).then((
                                            existingProducts,
                                          ) {
                                            if (existingProducts.isNotEmpty &&
                                                existingProducts[0].id !=
                                                    items[index].id) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (_) => AlertDialog(
                                                      title: Text("Error"),
                                                      content: Text(
                                                        "El SKU ya está en uso.",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          },
                                                          child: Text(
                                                            "Aceptar",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            } else {
                                              dbHelper
                                                  .actualizarProducto(
                                                    nombre.text,
                                                    detalle.text,
                                                    double.tryParse(
                                                          precio.text,
                                                        ) ??
                                                        0.0,
                                                    sku.text,
                                                    items[index].id!,
                                                  )
                                                  .whenComplete(() {
                                                    _refresh();
                                                    Navigator.pop(context);
                                                  });
                                            }
                                          });
                                        },
                                        child: const Text("Actualizar"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Cancelar"),
                                      ),
                                    ],
                                  ),
                                ],
                                title: const Text("Actualizar Producto"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      controller: nombre,
                                      decoration: const InputDecoration(
                                        label: Text("Nombre del Producto"),
                                      ),
                                    ),
                                    TextFormField(
                                      controller: detalle,
                                      decoration: const InputDecoration(
                                        label: Text("Descripción"),
                                      ),
                                    ),

                                    TextFormField(
                                      controller: sku,
                                      decoration: const InputDecoration(
                                        label: Text("SKU"),
                                      ),
                                    ),

                                    TextFormField(
                                      controller: precio,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        label: Text("Precio"),
                                      ),
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Por favor ingrese un precio';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'El precio debe ser un número válido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: generarCSVProductos,
              child: const Text("Exportar productos a CSV"),
            ),
          ),
        ],
      ),
    );
  }
}
