import 'package:flutter/material.dart';
import 'package:punto_de_venta/Json/usuario.dart';
import 'package:punto_de_venta/pages/sign.dart';
import 'package:punto_de_venta/basedato_helper.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final nombre = TextEditingController();
  final password = TextEditingController();
  final confimarpassword = TextEditingController();
  final rol = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final db = BasedatoHelper();
  registro() async {
    var existingUser = await db.getUsuario(nombre.text);
    if (existingUser != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("El usuario ya existe")));
      return;
    }

    var res = await db.crearUsuario(
      Usuario(nombre: nombre.text, password: password.text, rol: rol.text),
    );

    if (res > 0) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Sign()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Login",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 00.0,
        centerTitle: true,
        toolbarHeight: 60.2,
        toolbarOpacity: 0.8,
        elevation: 0.00,
        backgroundColor: const Color.fromARGB(255, 154, 124, 241),
      ),
      body: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Login",
              style: TextStyle(fontSize: 60.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 60),
            campoUsuario(nombre),
            campoContra(password),
            campoConfirmarContra(confimarpassword, password),
            campoRol(rol),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Tienes cuenta?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Sign()),
                    );
                  },
                  child: Text('Inicia Sesión'),
                ),
              ],
            ),

            SizedBox(height: 60),
            Container(
              height: 55,
              width: MediaQuery.of(context).size.width * .9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.deepPurple,
              ),

              child: TextButton(
                onPressed: () {
                  registro();
                },
                child: Text(
                  "Registrarse",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget campoUsuario(TextEditingController controller) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
    child: TextFormField(
      validator: (value) {
        if (value!.isEmpty) {
          return 'Usuario requerido';
        }
        return null;
      },
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.person_outline),
        hintText: "Escriba un usuario",
        fillColor: Colors.white,
        filled: true,
      ),
    ),
  );
}

Widget campoContra(TextEditingController controller) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
    child: TextFormField(
      validator: (value) {
        if (value!.isEmpty) {
          return 'Contraseña requerida';
        }
        return null;
      },
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock),
        hintText: "Escriba una contraseña",
        fillColor: Colors.white,
        filled: true,
      ),
    ),
  );
}

Widget campoConfirmarContra(
  TextEditingController controller,
  TextEditingController passController,
) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
    child: TextFormField(
      validator: (value) {
        if (value!.isEmpty) {
          return 'Contraseña requerida';
        } else if (value != passController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock),
        hintText: "Verifique la contraseña",
        fillColor: Colors.white,
        filled: true,
      ),
    ),
  );
}

Widget campoRol(TextEditingController controller) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
    child: TextFormField(
      validator: (value) {
        if (value!.isEmpty) {
          return 'Rol requerido';
        }
        return null;
      },
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.person_outline),
        hintText: "Escriba un rol (admin/vendedor)",
        fillColor: Colors.white,
        filled: true,
      ),
    ),
  );
}
