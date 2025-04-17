import 'package:flutter/material.dart';
import 'TelasDoAPP/PaginaDasMinhasDenuncias.dart';
import 'TelasDoAPP/paginaConfiguracoes.dart';
import 'TelasDoAPP/paginaDasDenuncias.dart';

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  _PaginaPrincipalState createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int _selectedIndex = 0;

  // Lista de títulos correspondentes a cada item do navigation bar
  static const List<String> _titles = [
    'Denúncias',
    'Minhas Denúncias',
    'Definições'
  ];

  // Método que retorna a página com base no índice
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return paginaDasDenuncias();
      case 1:
        return paginaDasMinhasDenuncias();
      case 2:
        return PaginaConfiguracoes();
      default:
        return paginaDasDenuncias();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.white60,
      ),

      body: _getPage(_selectedIndex), // Chama o método para obter a página correta

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Denúncias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_sharp),
            label: 'Minhas Denúncias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Definições',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}