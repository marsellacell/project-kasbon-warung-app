import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class TransactionProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  List<Transaction> get activeTransactions =>
      _transactions.where((t) => t.status == TransactionStatus.active).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  TransactionProvider() {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('transactions')
          .select('*')
          .order('created_at', ascending: false);

      _transactions = (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTransaction({
    required String customerId,
    required String namaBarang,
    required double nominal,
    String? deskripsi,
    required DateTime tanggal,
    DateTime? tenggat,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('transactions').insert({
        'customer_id': customerId,
        'nama_barang': namaBarang,
        'nominal': nominal,
        'deskripsi': deskripsi,
        'tanggal': tanggal.toIso8601String(),
        'tenggat': tenggat?.toIso8601String(),
        'status': 'active',
      });

      await fetchTransactions();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransactionStatus(
    String id,
    TransactionStatus status,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String statusStr;
      switch (status) {
        case TransactionStatus.paid:
          statusStr = 'paid';
          break;
        case TransactionStatus.overdue:
          statusStr = 'overdue';
          break;
        default:
          statusStr = 'active';
      }

      await _supabase
          .from('transactions')
          .update({'status': statusStr})
          .eq('id', id);
      await fetchTransactions();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('transactions').delete().eq('id', id);
      await fetchTransactions();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Transaction> getTransactionsByCustomer(String customerId) {
    return _transactions.where((t) => t.customerId == customerId).toList();
  }

  List<Transaction> getActiveTransactionsByCustomer(String customerId) {
    return _transactions
        .where(
          (t) =>
              t.customerId == customerId &&
              t.status == TransactionStatus.active,
        )
        .toList();
  }

  double getTotalActiveKasbon() {
    return activeTransactions.fold(0, (sum, t) => sum + t.nominal);
  }

  double getTotalActiveKasbonByCustomer(String customerId) {
    return getActiveTransactionsByCustomer(
      customerId,
    ).fold(0, (sum, t) => sum + t.nominal);
  }

  Transaction? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
