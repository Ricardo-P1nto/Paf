import 'package:flutter/material.dart';
import 'TelasDoNavigationBarItem/PaginaDasMinhasDenuncias.dart';
import 'TelasDoNavigationBarItem/paginaConfiguracoes.dart';
import 'TelasDoNavigationBarItem/paginaDasDenuncias.dart';

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  _PaginaPrincipalState createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Pagina Principal',
    'Denuncias',
    'Minhas Denuncias', 
    'Definições'
  ];

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

      body: Center(
        child: _selectedIndex == 0
            ? const Text('Home Page')
            : _selectedIndex == 1
            ? paginaDasDenuncias()
            : _selectedIndex == 2
            ? paginaDasMinhasDenuncias()
            : PaginaConfiguracoes(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Denuncias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_sharp),
            label: 'Minhas Denuncias',
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