import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

class CustomerProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CustomerProvider() {
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('customers')
          .select('*')
          .order('created_at', ascending: false);

      _customers = (response as List)
          .map((json) => Customer.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCustomer({
    required String nama,
    String? hp,
    String? alamat,
    double limitKredit = 0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('customers').insert({
        'nama': nama,
        'hp': hp,
        'alamat': alamat,
        'limit_kredit': limitKredit,
      });

      await fetchCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(
    String id, {
    String? nama,
    String? hp,
    String? alamat,
    double? limitKredit,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (nama != null) updates['nama'] = nama;
      if (hp != null) updates['hp'] = hp;
      if (alamat != null) updates['alamat'] = alamat;
      if (limitKredit != null) updates['limit_kredit'] = limitKredit;

      await _supabase.from('customers').update(updates).eq('id', id);
      await fetchCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('customers').delete().eq('id', id);
      await fetchCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    return _customers
        .where(
          (c) =>
              c.nama.toLowerCase().contains(query.toLowerCase()) ||
              (c.hp?.toLowerCase().contains(query.toLowerCase()) ?? false),
        )
        .toList();
  }
}
