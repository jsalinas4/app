import 'package:flutter/material.dart';
import 'reconocimiento.dart';
import 'registro.dart';

void main() {
  runApp(MaterialApp(
    home: MenuApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MenuApp extends StatefulWidget {
  @override
  _MenuAppState createState() => _MenuAppState();
}

class _MenuAppState extends State<MenuApp> {
  int _paginaSeleccionada = 0;

  final List<Widget> _paginas = [
    ReconocimientoVista(),
    RegistroVista(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _paginaSeleccionada = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reconocimiento Facial")),
      body: _paginas[_paginaSeleccionada],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaSeleccionada,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Reconocer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Registrar',
          ),
        ],
      ),
    );
  }
}
