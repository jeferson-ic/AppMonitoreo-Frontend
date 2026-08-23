import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'map_screen.dart';
import 'historial_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;
  String _rol = 'USUARIO';
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final rol = await StorageService.getRol() ?? 'USUARIO';
    final nombre = await StorageService.getNombre() ?? '';
    setState(() {
      _rol = rol;
      _nombre = nombre;
    });
  }

  Future<void> _cerrarSesion() async {
    await StorageService.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  List<Widget> get _pantallas => [
        const MapScreen(),
        const HistorialScreen(),
        if (_rol == 'ADMIN') const AdminScreen(),
      ];

  List<BottomNavigationBarItem> get _items => [
        const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.history), label: 'Historial'),
        if (_rol == 'ADMIN')
          const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, $_nombre'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: _cerrarSesion),
        ],
      ),
      body: IndexedStack(index: _indice, children: _pantallas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice,
        onTap: (i) => setState(() => _indice = i),
        items: _items,
      ),
    );
  }
}
