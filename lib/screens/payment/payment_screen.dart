import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/transaction.dart';
import '../../utils/currency_formatter.dart';
import '../../config/theme.dart';

class PaymentScreen extends StatefulWidget {
  final String? customerId;
  final String? transactionId;

  const PaymentScreen({super.key, this.customerId, this.transactionId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _catatanController = TextEditingController();

  String? _selectedCustomerId;
  Transaction? _selectedTransaction;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
    _selectedTransaction = widget.transactionId != null
        ? context.read<TransactionProvider>().getTransactionById(
            widget.transactionId!,
          )
        : null;

    if (_selectedTransaction != null) {
      _jumlahController.text = _selectedTransaction!.nominal.toString();
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih pelanggan')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final paymentProvider = context.read<PaymentProvider>();
    final success = await paymentProvider.addPayment(
      customerId: _selectedCustomerId!,
      transactionId: _selectedTransaction?.id,
      jumlah: double.parse(_jumlahController.text),
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      // Update transaction status if fully paid
      if (_selectedTransaction != null) {
        final transactionProvider = context.read<TransactionProvider>();
        final payments = paymentProvider.getPaymentsByTransaction(
          _selectedTransaction!.id,
        );
        final totalPaid = payments.fold(0.0, (sum, p) => sum + p.jumlah);

        if (totalPaid >= _selectedTransaction!.nominal) {
          await transactionProvider.updateTransactionStatus(
            _selectedTransaction!.id,
            TransactionStatus.paid,
          );
        }
      }

      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paymentProvider.error ?? 'Gagal menambahkan pembayaran',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _translate(String key) {
    final Map<String, String> translations = {
      'payment': 'Pembayaran',
      'namaPelanggan': 'Nama Pelanggan',
      'jumlahPembayaran': 'Jumlah Pembayaran',
      'catatan': 'Catatan',
      'selectTransaction': 'Pilih Kasbon (Opsional)',
      'save': 'Simpan',
      'cancel': 'Batal',
    };
    return translations[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    // Get active transactions for selected customer
    List<Transaction> availableTransactions = [];
    if (_selectedCustomerId != null) {
      availableTransactions = transactionProvider
          .getActiveTransactionsByCustomer(_selectedCustomerId!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('payment')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.successGradient,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Customer Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCustomerId,
                      decoration: InputDecoration(
                        labelText: _translate('namaPelanggan'),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                      ),
                      items: customerProvider.customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer.id,
                          child: Text(customer.nama),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerId = value;
                          _selectedTransaction = null;
                          _jumlahController.clear();
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih pelanggan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Transaction Dropdown (Optional)
                    if (availableTransactions.isNotEmpty) ...[
                      DropdownButtonFormField<Transaction>(
                        value: _selectedTransaction,
                        decoration: InputDecoration(
                          labelText: _translate('selectTransaction'),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceColor,
                        ),
                        hint: const Text('Pilih kasbon (opsional)'),
                        items: availableTransactions.map((transaction) {
                          return DropdownMenuItem(
                            value: transaction,
                            child: Text(
                              '${transaction.namaBarang} - ${CurrencyFormatter.format(transaction.nominal)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTransaction = value;
                            if (value != null) {
                              _jumlahController.text = value.nominal.toString();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Jumlah Pembayaran
                    TextFormField(
                      controller: _jumlahController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _translate('jumlahPembayaran'),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: AppTheme.successColor,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        prefixText: 'Rp ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah harus diisi';
                        }
                        final jumlah = double.tryParse(value);
                        if (jumlah == null || jumlah <= 0) {
                          return 'Jumlah harus angka positif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Catatan
                    TextFormField(
                      controller: _catatanController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: _translate('catatan'),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.note_outlined,
                            color: AppTheme.infoColor,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_translate('cancel')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _translate('save'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
