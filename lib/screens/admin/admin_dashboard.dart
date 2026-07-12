import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'records_tab.dart';
import 'workers_tab.dart';
import 'zones_tab.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Administrador'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'Registros'),
              Tab(icon: Icon(Icons.people), text: 'Trabajadores'),
              Tab(icon: Icon(Icons.map), text: 'Zonas'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService().logout();
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            RecordsTab(),
            WorkersTab(),
            ZonesTab(),
          ],
        ),
      ),
    );
  }
}
