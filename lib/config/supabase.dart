import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase Configuration
// Ganti dengan credentials Supabase lo
class SupabaseConfig {
  static const String supabaseUrl = 'https://vaudijtrerdpwjqmdblx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZhdWRpanRyZXJkcHdqcW1kYmx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMDUwMjUsImV4cCI6MjA4NzY4MTAyNX0.MAN2cSJTIiJr400-D9hi0Nl4SJyxQx5qZwyTx2IVwUA';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
