import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/user.dart' as models;

class AuthProvider extends ChangeNotifier {
  final sb.SupabaseClient _supabase = sb.Supabase.instance.client;

  sb.User? _authUser;
  models.User? _appUser;
  bool _isLoading = false;
  String? _error;

  sb.User? get authUser => _authUser;
  models.User? get appUser => _appUser;
  bool get isAuthenticated => _authUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _checkCurrentSession();
  }

  Future<void> _checkCurrentSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _authUser = session.user;
      await _fetchAppUser();
    }
  }

  Future<void> _fetchAppUser() async {
    if (_authUser == null) return;

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', _authUser!.id)
        .maybeSingle();

    if (response != null) {
      _appUser = models.User.fromJson(response);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _authUser = response.user;
        await _fetchAppUser();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(
    String email,
    String password,
    String nama,
    String role,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _authUser = response.user;

        // Create user profile in users table
        await _supabase.from('users').insert({
          'id': _authUser!.id,
          'email': email,
          'nama': nama,
          'role': role,
        });

        await _fetchAppUser();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _authUser = null;
    _appUser = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
