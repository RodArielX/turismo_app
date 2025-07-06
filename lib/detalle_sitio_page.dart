import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/rol_service.dart';

class DetalleSitioPage extends StatefulWidget {
  final Map sitio;

  const DetalleSitioPage({super.key, required this.sitio});

  @override
  State<DetalleSitioPage> createState() => _DetalleSitioPageState();
}

class _DetalleSitioPageState extends State<DetalleSitioPage> {
  final _resenaController = TextEditingController();
  List<dynamic> resenas = [];

  @override
  void initState() {
    super.initState();
    cargarResenas();
  }

  Future<void> cargarResenas() async {
    final data = await Supabase.instance.client
        .from('resenas')
        .select('id, texto, fecha, autor:usuarios(correo)')
        .eq('sitio_id', widget.sitio['id'])
        .order('fecha', ascending: false);

    setState(() {
      resenas = data;
    });
  }

  Future<List> cargarRespuestas(String resenaId) async {
    final data = await Supabase.instance.client
        .from('respuestas')
        .select('texto, fecha, autor:usuarios(correo)')
        .eq('resena_id', resenaId)
        .order('fecha', ascending: true);

    return data;
  }

  Future<void> publicarResena() async {
    final texto = _resenaController.text.trim();
    if (texto.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client.from('resenas').insert({
      'sitio_id': widget.sitio['id'],
      'texto': texto,
      'autor': userId,
    });

    _resenaController.clear();
    cargarResenas();
  }

  void mostrarDialogoRespuesta(String resenaId) async {
    final rol = await RolService.obtenerRolUsuarioActual();

    if (rol != 'publicador') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo los publicadores pueden responder reseñas')),
      );
      return;
    }

    final TextEditingController respuestaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Responder reseña'),
        content: TextField(
          controller: respuestaCtrl,
          decoration: const InputDecoration(hintText: 'Escribe tu respuesta'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final texto = respuestaCtrl.text.trim();
              if (texto.isNotEmpty) {
                final userId = Supabase.instance.client.auth.currentUser!.id;

                await Supabase.instance.client.from('respuestas').insert({
                  'resena_id': resenaId,
                  'autor': userId,
                  'texto': texto,
                });

                Navigator.pop(context);
                cargarResenas();
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sitio = widget.sitio;

    return Scaffold(
      appBar: AppBar(title: Text(sitio['titulo'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sitio['descripcion'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Ubicación: ${sitio['ubicacion']}',
              style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
            ),
            const Divider(height: 40, thickness: 1.2),

            Text('Reseñas', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Expanded(
              child: resenas.isEmpty
                  ? const Center(child: Text('No hay reseñas aún.', style: TextStyle(fontSize: 16, color: Colors.black54)))
                  : ListView.builder(
                      itemCount: resenas.length,
                      itemBuilder: (context, index) {
                        final resena = resenas[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resena['texto'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Por: ${resena['autor']['correo']}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),

                                const SizedBox(height: 12),

                                FutureBuilder<List>(
                                  future: cargarRespuestas(resena['id']),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Padding(
                                        padding: EdgeInsets.only(left: 16),
                                        child: Text('Cargando respuestas...', style: TextStyle(fontSize: 14, color: Colors.black54)),
                                      );
                                    }
                                    final respuestas = snapshot.data!;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: respuestas.map((r) {
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 20, bottom: 8),
                                          child: Card(
                                            color: Colors.grey[100],
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            child: ListTile(
                                              title: Text(r['texto']),
                                              subtitle: Text('↪ ${r['autor']['correo']}'),
                                              dense: true,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.reply),
                                    label: const Text('Responder'),
                                    onPressed: () => mostrarDialogoRespuesta(resena['id']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 32),

            TextField(
              controller: _resenaController,
              decoration: InputDecoration(
                labelText: 'Escribir reseña',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: publicarResena,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.indigo[700],
                ),
                child: const Text('Publicar reseña', style: TextStyle(fontSize: 16), selectionColor: Colors.white12,),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
