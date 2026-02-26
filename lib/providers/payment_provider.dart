import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

class PaymentProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _error;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PaymentProvider() {
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('payments')
          .select('*')
          .order('created_at', ascending: false);

      _payments = (response as List)
          .map((json) => Payment.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addPayment({
    required String customerId,
    String? transactionId,
    required double jumlah,
    DateTime? tanggal,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('payments').insert({
        'customer_id': customerId,
        'transaction_id': transactionId,
        'jumlah': jumlah,
        'tanggal': (tanggal ?? DateTime.now()).toIso8601String(),
      });

      await fetchPayments();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Payment> getPaymentsByCustomer(String customerId) {
    return _payments.where((p) => p.customerId == customerId).toList();
  }

  List<Payment> getPaymentsByTransaction(String transactionId) {
    return _payments.where((p) => p.transactionId == transactionId).toList();
  }

  double getTotalPaymentsByCustomer(String customerId) {
    return getPaymentsByCustomer(
      customerId,
    ).fold(0, (sum, p) => sum + p.jumlah);
  }

  double getTotalPaymentsThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _payments
        .where(
          (p) =>
              p.tanggal.isAfter(startOfMonth) ||
              p.tanggal.isAtSameMomentAs(startOfMonth),
        )
        .fold(0, (sum, p) => sum + p.jumlah);
  }

  double getTotalPaymentsThisYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return _payments
        .where(
          (p) =>
              p.tanggal.isAfter(startOfYear) ||
              p.tanggal.isAtSameMomentAs(startOfYear),
        )
        .fold(0, (sum, p) => sum + p.jumlah);
  }
}
