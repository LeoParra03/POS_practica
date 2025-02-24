import 'package:flutter/material.dart';
import 'package:punto_de_venta/Json/venta.dart';
import 'package:punto_de_venta/Json/producto.dart';
import 'package:punto_de_venta/basedato_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:csv/csv.dart';

class VentasGeneradas extends StatefulWidget {
  @override
  _VentasGeneradasState createState() => _VentasGeneradasState();
}

class _VentasGeneradasState extends State<VentasGeneradas> {
  final BasedatoHelper dbHelper = BasedatoHelper();

  Future<void> generarCSV() async {
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

    final path = '${directory.path}/ventas.csv';
    List<List<String>> csvData = [
      ['Venta ID', 'Fecha', 'Productos', 'Total'],
    ];
    List<Venta> ventasData = await dbHelper.obtenerVentas();
    for (var venta in ventasData) {
      List<String> productosEnVenta = [];
      double totalVenta = 0;

      for (var productoVenta in venta.productos) {
        var producto = await dbHelper.obtenerProductoPorId(
          productoVenta.productoId,
        );
        String productoConCantidad =
            '${producto.nombre} x ${productoVenta.cantidad}';
        productosEnVenta.add(productoConCantidad);
        totalVenta += productoVenta.total;
      }
      String productosString = productosEnVenta.join(', ');
      csvData.add([
        venta.id.toString(),
        venta.fecha,
        productosString,
        '\$${totalVenta.toStringAsFixed(2)}',
      ]);
    }

    String csvString = const ListToCsvConverter().convert(csvData);
    final file = File(path);
    await file.writeAsString(csvString);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("CSV exportado exitosamente a: $path")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Venta>>(
        future: dbHelper.obtenerVentas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay ventas generadas"));
          } else {
            var ventasData = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: ventasData.length,
                    itemBuilder: (context, index) {
                      var ventaItem = ventasData[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        elevation: 4,
                        child: ExpansionTile(
                          title: Text(
                            "Venta ID: ${ventaItem.id} - Fecha: ${ventaItem.fecha} - Total: \$${ventaItem.total.toStringAsFixed(2)}",
                          ),
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...ventaItem.productos.map((productoVenta) {
                                  return FutureBuilder<Producto>(
                                    future: dbHelper.obtenerProductoPorId(
                                      productoVenta.productoId,
                                    ),
                                    builder: (context, productoSnapshot) {
                                      if (productoSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return ListTile(
                                          title: Text("Cargando producto..."),
                                        );
                                      } else if (productoSnapshot.hasError) {
                                        return ListTile(
                                          title: Text(
                                            "Error al obtener producto",
                                          ),
                                        );
                                      } else if (!productoSnapshot.hasData) {
                                        return ListTile(
                                          title: Text("Producto no encontrado"),
                                        );
                                      } else {
                                        var producto = productoSnapshot.data!;
                                        return ListTile(
                                          title: Text(
                                            "Producto: ${producto.nombre} - Cantidad: ${productoVenta.cantidad} - Total: \$${productoVenta.total.toStringAsFixed(2)}",
                                          ),
                                        );
                                      }
                                    },
                                  );
                                }).toList(),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: generarCSV,
                  child: Text("Exportar ventas a CSV"),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
