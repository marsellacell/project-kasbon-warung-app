import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/transaction.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  String _translate(String key) {
    final Map<String, String> translations = {
      'riwayatKasbon': 'Riwayat Kasbon',
      'saldoKasbon': 'Saldo Kasbon',
      'addKasbon': 'Tambah Kasbon',
      'payment': 'Pembayaran',
      'noData': 'Tidak ada data',
      'active': 'Aktif',
      'paid': 'Lunas',
      'overdue': 'Jatuh Tempo',
    };
    return translations[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    final customer = customerProvider.getCustomerById(customerId);
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final transactions = transactionProvider.getTransactionsByCustomer(
      customerId,
    );
    final activeTransactions = transactions
        .where((t) => t.status == TransactionStatus.active)
        .toList();
    final totalActiveKasbon = activeTransactions.fold(
      0.0,
      (sum, t) => sum + t.nominal,
    );

    return Scaffold(
      appBar: AppBar(title: Text(customer.nama)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Text(
                            customer.nama.isNotEmpty
                                ? customer.nama[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.nama,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (customer.hp != null)
                                Text(
                                  customer.hp!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (customer.alamat != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(customer.alamat!)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _translate('saldoKasbon'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            CurrencyFormatter.format(totalActiveKasbon),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (customer.limitKredit > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Limit Kredit: ${CurrencyFormatter.format(customer.limitKredit)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/add-kasbon',
                      arguments: customerId,
                    ),
                    icon: const Icon(Icons.add_card),
                    label: Text(_translate('addKasbon')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/payment',
                      arguments: customerId,
                    ),
                    icon: const Icon(Icons.payment),
                    label: Text(_translate('payment')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Transaction History
            Text(
              _translate('riwayatKasbon'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _translate('noData'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...transactions.map(
                (transaction) => _TransactionCard(
                  transaction: transaction,
                  translate: _translate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String Function(String) translate;

  const _TransactionCard({required this.transaction, required this.translate});

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.active:
        return Colors.orange;
      case TransactionStatus.paid:
        return Colors.green;
      case TransactionStatus.overdue:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (transaction.status) {
      case TransactionStatus.active:
        return translate('active');
      case TransactionStatus.paid:
        return translate('paid');
      case TransactionStatus.overdue:
        return translate('overdue');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.namaBarang,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.format(transaction.tanggal),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  if (transaction.tenggat != null)
                    Text(
                      'Tenggat: ${DateFormatter.format(transaction.tenggat)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: transaction.isOverdue
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(transaction.nominal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
