import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'publicador_page.dart';
import 'sitios_page.dart';
import 'services/rol_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? rol;
  String? email;

  @override
  void initState() {
    super.initState();
    obtenerDatosUsuario();
  }

  Future<void> obtenerDatosUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;

    final r = await RolService.obtenerRolUsuarioActual();

    // Debug en consola (puedes ignorar advertencia de producción)
    // ignore: avoid_print
    print('Usuario ID: ${user?.id}');
    // ignore: avoid_print
    print('Correo: ${user?.email}');
    // ignore: avoid_print
    print('Rol detectado: $r');

    setState(() {
      rol = r;
      email = user?.email ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (rol == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (rol != 'publicador' && rol != 'visitante') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ Rol no válido o no registrado en Supabase',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text('Correo: $email', style: theme.textTheme.bodyMedium),
                Text('Rol detectado: $rol', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (rol == 'publicador') {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Bienvenido Publicador: $email'),
            bottom: TabBar(
              indicatorColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.place), text: 'Sitios publicados'),
                Tab(icon: Icon(Icons.add_box), text: 'Nuevo sitio'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ],
          ),
          body: const TabBarView(
            children: [
              SitiosPage(),
              PublicadorPage(),
            ],
          ),
        ),
      );
    }

    // Visitante
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido Visitante: $email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: const SitiosPage(),
    );
  }
}
