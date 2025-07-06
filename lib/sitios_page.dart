import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detalle_sitio_page.dart';

class SitiosPage extends StatefulWidget {
  const SitiosPage({super.key});

  @override
  State<SitiosPage> createState() => _SitiosPageState();
}

class _SitiosPageState extends State<SitiosPage> {
  List<dynamic> sitios = [];

  @override
  void initState() {
    super.initState();
    cargarSitios();
  }

  Future<void> cargarSitios() async {
    try {
      final data = await Supabase.instance.client
          .from('sitios')
          .select('id, titulo, descripcion, ubicacion, fecha, fotos')
          .order('fecha', ascending: false);

      setState(() {
        sitios = data;
      });
    } catch (e) {
      // Puedes mostrar un snackbar o algo para indicar el error
      print('Error al cargar sitios: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sitios Turísticos'),
        centerTitle: true,
        elevation: 2,
      ),
      body: sitios.isEmpty
          ? const Center(
              child: Text(
                'No hay sitios turísticos disponibles.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: cargarSitios,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: sitios.length,
                itemBuilder: (context, index) {
                  final sitio = sitios[index];
                  final fotos = sitio['fotos'] as List<dynamic>?;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetalleSitioPage(sitio: sitio),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen principal (primera foto) o placeholder
                          if (fotos != null && fotos.isNotEmpty)
                            SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: Image.network(
                                fotos[0],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 60),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              height: 180,
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sitio['titulo'],
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  sitio['descripcion'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        sitio['ubicacion'] ?? 'Sin ubicación',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Mostrar miniaturas si hay más fotos
                          if (fotos != null && fotos.length > 1)
                            SizedBox(
                              height: 100,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: fotos.length - 1,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, i) {
                                  final url = fotos[i + 1];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      width: 120,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey.shade200,
                                          width: 120,
                                          height: 100,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
