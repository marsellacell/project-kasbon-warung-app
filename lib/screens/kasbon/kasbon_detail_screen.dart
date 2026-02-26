import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/transaction.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class KasbonDetailScreen extends StatelessWidget {
  final String transactionId;

  const KasbonDetailScreen({super.key, required this.transactionId});

  String _translate(String key) {
    final Map<String, String> translations = {
      'detail': 'Detail Kasbon',
      'customer': 'Pelanggan',
      'namaBarang': 'Nama Barang',
      'nominal': 'Nominal',
      'deskripsi': 'Deskripsi',
      'tanggal': 'Tanggal',
      'tenggat': 'Tenggat',
      'status': 'Status',
      'active': 'Aktif',
      'paid': 'Lunas',
      'overdue': 'Jatuh Tempo',
      'payment': 'Pembayaran',
      'delete': 'Hapus',
      'markAsPaid': 'Tandai Lunas',
    };
    return translations[key] ?? key;
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.active:
        return Colors.orange;
      case TransactionStatus.paid:
        return Colors.green;
      case TransactionStatus.overdue:
        return Colors.red;
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.active:
        return _translate('active');
      case TransactionStatus.paid:
        return _translate('paid');
      case TransactionStatus.overdue:
        return _translate('overdue');
    }
  }

  Future<void> _markAsPaid(BuildContext context) async {
    final transactionProvider = context.read<TransactionProvider>();
    await transactionProvider.updateTransactionStatus(
      transactionId,
      TransactionStatus.paid,
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTransaction(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kasbon'),
        content: const Text('Apakah Anda yakin ingin menghapus kasbon ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final transactionProvider = context.read<TransactionProvider>();
      await transactionProvider.deleteTransaction(transactionId);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    final transaction = transactionProvider.getTransactionById(transactionId);
    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_translate('detail'))),
        body: const Center(child: Text('Transaction not found')),
      );
    }

    final customer = customerProvider.getCustomerById(transaction.customerId);
    final payments = paymentProvider.getPaymentsByTransaction(transactionId);
    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.jumlah);
    final remaining = transaction.nominal - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('detail')),
        actions: [
          if (transaction.status == TransactionStatus.active)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () => _markAsPaid(context),
              tooltip: _translate('markAsPaid'),
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteTransaction(context),
            tooltip: _translate('delete'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _translate('namaBarang'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              transaction.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(transaction.status),
                            style: TextStyle(
                              color: _getStatusColor(transaction.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      transaction.namaBarang,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: _translate('nominal'),
                      value: CurrencyFormatter.format(transaction.nominal),
                    ),
                    _InfoRow(
                      label: _translate('tanggal'),
                      value: DateFormatter.format(transaction.tanggal),
                    ),
                    if (transaction.tenggat != null)
                      _InfoRow(
                        label: _translate('tenggat'),
                        value: DateFormatter.format(transaction.tenggat!),
                        valueColor: transaction.isOverdue ? Colors.red : null,
                      ),
                    if (transaction.deskripsi != null &&
                        transaction.deskripsi!.isNotEmpty)
                      _InfoRow(
                        label: _translate('deskripsi'),
                        value: transaction.deskripsi!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Info
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    customer?.nama.isNotEmpty == true
                        ? customer!.nama[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(customer?.nama ?? 'Unknown'),
                subtitle: Text(customer?.hp ?? '-'),
                trailing: const Icon(Icons.chevron_right),
                onTap: customer != null
                    ? () => Navigator.pushNamed(
                        context,
                        '/customer-detail',
                        arguments: customer.id,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Payment Summary
            if (transaction.status == TransactionStatus.active) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sisa Pembayaran'),
                          Text(
                            CurrencyFormatter.format(
                              remaining > 0 ? remaining : 0,
                            ),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/payment',
                            arguments: {
                              'customerId': transaction.customerId,
                              'transactionId': transactionId,
                            },
                          ),
                          icon: const Icon(Icons.payment),
                          label: Text(_translate('payment')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
          ),
        ],
      ),
    );
  }
}
