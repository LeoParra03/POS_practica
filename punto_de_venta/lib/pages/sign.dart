import 'package:flutter/material.dart';
import 'package:punto_de_venta/Json/usuario.dart';
import 'package:punto_de_venta/basedato_helper.dart';
import 'package:punto_de_venta/pages/vendedor.dart';
import 'package:punto_de_venta/pages/admin.dart';
import 'package:punto_de_venta/pages/registro.dart';

class Sign extends StatefulWidget {
  const Sign({super.key});

  static String id = 'sign in';

  @override
  _SignState createState() => _SignState();
}

class _SignState extends State<Sign> {
  final nombre = TextEditingController();
  final password = TextEditingController();
  final db = BasedatoHelper();
  final formKey = GlobalKey<FormState>();

  bool isLoginTrue = false;

  login() async {
    Usuario? user = await db.getUsuario(nombre.text);
    if (user != null && user.password == password.text) {
      if (!mounted) return;
      if (user.rol == "admin") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Admin()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Vendedor()),
        );
      }
    } else {
      setState(() {
        isLoginTrue = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Sign in",
                  style: TextStyle(fontSize: 60.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 60),
                campoUsuario(nombre),
                campoContra(password),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No tienes cuenta?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Registro(),
                          ),
                        );
                      },
                      child: Text('Registrate'),
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
                      login();
                    },
                    child: Text(
                      "Ingresar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
