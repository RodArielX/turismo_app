import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicadorPage extends StatefulWidget {
  const PublicadorPage({super.key});

  @override
  State<PublicadorPage> createState() => _PublicadorPageState();
}

class _PublicadorPageState extends State<PublicadorPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _imagenes = [];

  Future<void> _seleccionarImagen(bool desdeCamara) async {
    final XFile? imagen = await _picker.pickImage(
      source: desdeCamara ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagen != null) {
      final file = File(imagen.path);
      final tamanoEnMB = await file.length() / (1024 * 1024);

      if (tamanoEnMB > 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen demasiado grande (máx 2MB)')),
        );
        return;
      }

      if (_imagenes.length < 5) {
        final bytes = await imagen.readAsBytes();
        setState(() {
          _imagenes.add({
            'name': imagen.name,
            'bytes': bytes,
          });
        });
      }
    }
  }

  Future<void> _publicarSitio() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final urls = <String>[];

      for (final imagen in _imagenes) {
        final fileBytes = imagen['bytes'] as Uint8List;
        final fileExt = imagen['name'].split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'sitios/$userId/$fileName';

        final storage = Supabase.instance.client.storage;

        await storage
            .from('sitios-fotos')
            .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: const FileOptions(upsert: true),
            );

        final url = storage.from('sitios-fotos').getPublicUrl(filePath);
        urls.add(url);
      }

      await Supabase.instance.client.from('sitios').insert({
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'autor': userId,
        'fecha': DateTime.now().toIso8601String(),
        'fotos': urls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sitio y fotos publicadas')),
      );

      _tituloController.clear();
      _descripcionController.clear();
      _ubicacionController.clear();
      setState(() {
        _imagenes.clear();
      });
    } catch (e) {
      print('❌ Error al publicar sitio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar sitio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar sitio turístico')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (val) =>
                        val!.isEmpty ? 'Ingrese el título' : null,
                  ),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  TextFormField(
                    controller: _ubicacionController,
                    decoration: const InputDecoration(labelText: 'Ubicación'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _imagenes
                  .map(
                    (img) => Image.memory(
                      img['bytes'],
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                  .toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _seleccionarImagen(true),
                  icon: const Icon(Icons.camera),
                  label: const Text('Cámara'),
                ),
                TextButton.icon(
                  onPressed: () => _seleccionarImagen(false),
                  icon: const Icon(Icons.image),
                  label: const Text('Galería'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _publicarSitio,
              child: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
