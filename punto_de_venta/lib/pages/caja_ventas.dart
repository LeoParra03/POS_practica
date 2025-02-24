import 'package:flutter/material.dart';
import 'package:punto_de_venta/Json/producto.dart';
import 'package:punto_de_venta/Json/venta.dart';
import 'package:punto_de_venta/basedato_helper.dart';

class CajaVentas extends StatefulWidget {
  @override
  _CajaVentasState createState() => _CajaVentasState();
}

class _CajaVentasState extends State<CajaVentas> {
  final BasedatoHelper dbHelper = BasedatoHelper();
  late Future<List<Producto>> productos;
  final palabraclave = TextEditingController();
  List<Venta> ventasTemporales = [];

  @override
  void initState() {
    super.initState();
    productos = dbHelper.obtenerProductos();
  }

  Future<List<Producto>> obtenerTodoProductos() {
    return dbHelper.obtenerProductos();
  }

  Future<List<Producto>> buscarProducto() {
    return dbHelper.buscarProducto(palabraclave.text);
  }

  void agregarProducto(Producto producto) {
    setState(() {
      if (ventasTemporales.isEmpty) {
        ventasTemporales.add(
          Venta(
            productos: [],
            total: 0.0,
            fecha: DateTime.now().toIso8601String(),
          ),
        );
      }

      var ventaActual = ventasTemporales.first;

      var productoExistente = ventaActual.productos.firstWhere(
        (p) => p.productoId == producto.id,
        orElse: () => ProductoVenta(productoId: -1, cantidad: 0, total: 0),
      );

      if (productoExistente.productoId != -1) {
        productoExistente.cantidad++;
        productoExistente.total = productoExistente.cantidad * producto.precio;
      } else {
        ventaActual.productos.add(
          ProductoVenta(
            productoId: producto.id!,
            cantidad: 1,
            total: producto.precio,
          ),
        );
      }

      ventaActual.total = ventaActual.productos.fold(
        0.0,
        (sum, p) => sum + p.total,
      );
    });
  }

  void eliminarProductoDeVenta(Venta ventaItem, ProductoVenta productoVenta) {
    setState(() {
      ventaItem.productos.remove(productoVenta);
      ventaItem.total = ventaItem.productos.fold(
        0.0,
        (sum, p) => sum + p.total,
      );
      if (ventaItem.productos.isEmpty) {
        ventasTemporales.remove(ventaItem);
      }
    });
  }

  void aumentarCantidad(
    Venta ventaItem,
    ProductoVenta productoVenta,
    Producto producto,
  ) {
    setState(() {
      productoVenta.cantidad++;
      productoVenta.total = productoVenta.cantidad * producto.precio;

      ventaItem.total = ventaItem.productos.fold(
        0.0,
        (sum, p) => sum + p.total,
      );
    });
  }

  void disminuirCantidad(
    Venta ventaItem,
    ProductoVenta productoVenta,
    Producto producto,
  ) {
    setState(() {
      if (productoVenta.cantidad > 1) {
        productoVenta.cantidad--;
        productoVenta.total = productoVenta.cantidad * producto.precio;
      } else {
        eliminarProductoDeVenta(ventaItem, productoVenta);
      }

      ventaItem.total = ventaItem.productos.fold(
        0.0,
        (sum, p) => sum + p.total,
      );
    });
  }

  void generarVenta() async {
    if (ventasTemporales.isNotEmpty) {
      var venta = ventasTemporales.first;

      int ventaId = await dbHelper.agregarVenta(venta);

      for (var productoVenta in venta.productos) {
        await dbHelper.insertarProductoVenta(ventaId, productoVenta);
      }

      setState(() {
        ventasTemporales.clear();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Venta generada exitosamente")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
              setState(() {
                productos =
                    value.isNotEmpty
                        ? buscarProducto()
                        : obtenerTodoProductos();
              });
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              icon: Icon(Icons.search),
              hintText: "Buscar productos",
            ),
          ),
        ),

        Expanded(
          child: FutureBuilder<List<Producto>>(
            future: productos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text("No hay productos disponibles"),
                );
              } else {
                var productosData = snapshot.data!;
                return ListView.builder(
                  itemCount: productosData.length,
                  itemBuilder: (context, index) {
                    var producto = productosData[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(producto.nombre[0])),
                      title: Text(producto.nombre),
                      subtitle: Text(
                        "SKU: ${producto.sku} - ${producto.descripcion}",
                      ),
                      trailing: Text("\$${producto.precio.toStringAsFixed(2)}"),
                      onTap: () => agregarProducto(producto),
                    );
                  },
                );
              }
            },
          ),
        ),

        Divider(),

        Expanded(
          child: ListView.builder(
            itemCount: ventasTemporales.length,
            itemBuilder: (context, index) {
              var ventaItem = ventasTemporales[index];
              return Column(
                children: [
                  Column(
                    children:
                        ventaItem.productos.map((productoVenta) {
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
                                  title: Text("Error al obtener producto"),
                                );
                              } else if (!productoSnapshot.hasData) {
                                return ListTile(
                                  title: Text("Producto no encontrado"),
                                );
                              } else {
                                var producto = productoSnapshot.data!;
                                return ListTile(
                                  title: Text(
                                    "${producto.nombre} - Cantidad: ${productoVenta.cantidad} - Total: \$${productoVenta.total.toStringAsFixed(2)}",
                                  ),
                                  leading: IconButton(
                                    icon: Icon(Icons.remove, color: Colors.red),
                                    onPressed:
                                        () => disminuirCantidad(
                                          ventaItem,
                                          productoVenta,
                                          producto,
                                        ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.add,
                                          color: Colors.green,
                                        ),
                                        onPressed:
                                            () => aumentarCantidad(
                                              ventaItem,
                                              productoVenta,
                                              producto,
                                            ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => eliminarProductoDeVenta(
                                              ventaItem,
                                              productoVenta,
                                            ),
                                      ),
                                    ],
                                  ),
                                  onLongPress:
                                      () => eliminarProductoDeVenta(
                                        ventaItem,
                                        productoVenta,
                                      ),
                                );
                              }
                            },
                          );
                        }).toList(),
                  ),
                ],
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: \$${ventasTemporales.isNotEmpty ? ventasTemporales.first.total.toStringAsFixed(2) : '0.00'}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: ventasTemporales.isNotEmpty ? generarVenta : null,
                  child: Text("Generar Venta"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
