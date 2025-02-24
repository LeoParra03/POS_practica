import 'package:flutter/material.dart';
import 'caja_ventas.dart'; // Importamos la caja de ventas
import 'ventas_generadas.dart'; // Importamos las ventas generadas

class Vendedor extends StatefulWidget {
  const Vendedor({super.key});
  static String id = 'vendedor_screen';
  _Vendedor createState() => _Vendedor();
}

class _Vendedor extends State<Vendedor> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return CajaVentas();
    } else {
      return VentasGeneradas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Panel de Vendedor")),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: "Caja de Ventas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Ventas Generadas",
          ),
        ],
      ),
    );
  }
}
