import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:punto_de_venta/Json/usuario.dart';
import 'package:punto_de_venta/Json/venta.dart';
import 'package:punto_de_venta/Json/producto.dart';

class BasedatoHelper {
  final database = "pos.db";
  static String posTablaNombre = "pos";

  String usuarios = '''
    CREATE TABLE usuarios(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT UNIQUE,
      password TEXT,
      rol TEXT
    )
  ''';

  String productos = '''
    CREATE TABLE productos(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT,
      descripcion TEXT,
      precio REAL,
      sku TEXT UNIQUE
    )
  ''';

  String ventas = '''
    CREATE TABLE ventas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      total REAL,
      fecha TEXT
    )
  ''';

  String ventaProductos = '''
    CREATE TABLE venta_productos(
      venta_id INTEGER,
      producto_id INTEGER,
      cantidad INTEGER,
      total REAL,
      FOREIGN KEY (venta_id) REFERENCES ventas(id),
      FOREIGN KEY (producto_id) REFERENCES productos(id),
      PRIMARY KEY (venta_id, producto_id)
    )
  ''';

  Future<Database> initDB() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'pos.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(usuarios);
        await db.execute(productos);
        await db.execute(ventas);
        await db.execute(ventaProductos);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(ventaProductos);
        }
      },
    );
  }

  Future<bool> autorizacion(Usuario usr) async {
    final Database db = await initDB();
    var result = await db.rawQuery(
      "select * from usuarios where nombre = '${usr.nombre}' AND password = '${usr.password}' ",
    );
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<int> crearUsuario(Usuario usr) async {
    final Database db = await initDB();
    return db.insert("usuarios", usr.toMap());
  }

  Future<Usuario?> getUsuario(String nombre) async {
    final Database db = await initDB();
    var res = await db.query(
      "usuarios",
      where: "nombre = ?",
      whereArgs: [nombre],
    );
    return res.isNotEmpty ? Usuario.fromMap(res.first) : null;
  }

  Future<int> agregarProducto(Producto producto) async {
    final Database db = await initDB();
    try {
      return await db.insert(
        "productos",
        producto.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } catch (e) {
      if (e.toString().contains("UNIQUE constraint failed: productos.sku")) {
        print("Error: El SKU ya existe");
      }
      return -1;
    }
  }

  Future<int> eliminarProducto(int id) async {
    final Database db = await initDB();
    return await db.delete("productos", where: "id = ?", whereArgs: [id]);
  }

  Future<List<Producto>> obtenerProductos() async {
    final Database db = await initDB();
    final List<Map<String, Object?>> res = await db.query("productos");

    return res.map((producto) => Producto.fromMap(producto)).toList();
  }

  Future<Producto> obtenerProductoPorId(int productoId) async {
    final Database db = await initDB();
    var result = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [productoId],
    );
    if (result.isNotEmpty) {
      return Producto.fromMap(result.first);
    }
    throw Exception('Producto no encontrado');
  }

  Future<List<Producto>> buscarProducto(String palabraclave) async {
    final Database db = await initDB();
    List<Map<String, Object?>> searchResult = await db.rawQuery(
      "SELECT * FROM productos WHERE nombre LIKE ?",
      ["%$palabraclave%"],
    );
    return searchResult.map((e) => Producto.fromMap(e)).toList();
  }

  Future<int> actualizarProducto(nombre, descripcion, precio, sku, id) async {
    final Database db = await initDB();
    return db.rawUpdate(
      'update productos set nombre = ?, descripcion = ?, precio = ?, sku = ? where id = ?',
      [nombre, descripcion, precio, sku, id],
    );
  }

  Future<List<Venta>> obtenerVentas() async {
    final db = await initDB();
    final List<Map<String, dynamic>> ventasMap = await db.query('ventas');
    Map<int, Venta> ventasMapeadas = {};

    for (var ventaData in ventasMap) {
      int ventaId = ventaData['id'];
      if (!ventasMapeadas.containsKey(ventaId)) {
        ventasMapeadas[ventaId] = Venta(
          id: ventaId,
          fecha: ventaData['fecha'],
          total: ventaData['total'],
          productos: [],
        );
      }

      final List<Map<String, dynamic>> productosMap = await db.query(
        'venta_productos',
        where: 'venta_id = ?',
        whereArgs: [ventaId],
      );

      ventasMapeadas[ventaId]!.productos =
          productosMap.map((producto) {
            return ProductoVenta(
              productoId: producto['producto_id'],
              cantidad: producto['cantidad'],
              total: producto['total'],
            );
          }).toList();
    }

    return ventasMapeadas.values.toList();
  }

  Future<int> agregarVenta(Venta venta) async {
    final BasedatoHelper dbHelper = BasedatoHelper();
    final Database db = await initDB();
    int ventaId = await db.insert("ventas", {
      "total": venta.total,
      "fecha": venta.fecha,
    });

    for (var producto in venta.productos) {
      if (producto.total == 0) {
        Producto prod = await dbHelper.obtenerProductoPorId(
          producto.productoId,
        );
        producto.total = prod.precio * producto.cantidad;
      }

      await db.insert("venta_productos", {
        "venta_id": ventaId,
        "producto_id": producto.productoId,
        "cantidad": producto.cantidad,
        "total": producto.total,
      });
    }

    return ventaId;
  }

  Future<int> insertarProductoVenta(
    int ventaId,
    ProductoVenta productoVenta,
  ) async {
    final Database db = await initDB();
    try {
      return await db.insert("venta_productos", {
        "venta_id": ventaId,
        "producto_id": productoVenta.productoId,
        "cantidad": productoVenta.cantidad,
        "total": productoVenta.total,
      });
    } catch (e) {
      print("Error al insertar producto en venta_productos: $e");
      return -1;
    }
  }
}
