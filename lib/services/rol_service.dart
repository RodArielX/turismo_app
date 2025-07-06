import 'package:supabase_flutter/supabase_flutter.dart';

class RolService {
  static Future<String?> obtenerRolUsuarioActual() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return null;

    final data = await Supabase.instance.client
        .from('usuarios')
        .select('rol')
        .eq('id', userId)
        .maybeSingle();

    return data?['rol'];
  }
}
