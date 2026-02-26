import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/transaction.dart';
import '../../utils/currency_formatter.dart';
import '../../config/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  String _translate(String key) {
    final Map<String, String> translations = {
      'reports': 'Laporan',
      'bulanan': 'Laporan Bulanan',
      'totalPendapatan': 'Total Pendapatan',
      'totalKasbonAktif': 'Total Kasbon Aktif',
      'totalKasbonLunas': 'Total Kasbon Lunas',
      'totalKasbonBaru': 'Total Kasbon Baru',
      'totalPelanggan': 'Total Pelanggan',
    };
    return translations[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    // Filter by selected month/year
    final startOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final endOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);

    final transactionsThisMonth = transactionProvider.transactions.where((t) {
      final date = t.tanggal;
      return date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();

    final paymentsThisMonth = paymentProvider.payments.where((p) {
      final date = p.tanggal;
      return date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();

    final activeTransactions = transactionProvider.transactions
        .where((t) => t.status == TransactionStatus.active)
        .toList();

    final paidTransactions = transactionsThisMonth
        .where((t) => t.status == TransactionStatus.paid)
        .toList();

    final newTransactions = transactionsThisMonth
        .where((t) => t.status == TransactionStatus.active)
        .toList();

    final totalPendapatan = paymentsThisMonth.fold(
      0.0,
      (sum, p) => sum + p.jumlah,
    );
    final totalKasbonAktif = activeTransactions.fold(
      0.0,
      (sum, t) => sum + t.nominal,
    );
    final totalKasbonLunas = paidTransactions.fold(
      0.0,
      (sum, t) => sum + t.nominal,
    );
    final totalKasbonBaru = newTransactions.fold(
      0.0,
      (sum, t) => sum + t.nominal,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _translate('reports'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.primaryGradient,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month/Year Selector Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedMonth == 1) {
                                _selectedMonth = 12;
                                _selectedYear--;
                              } else {
                                _selectedMonth--;
                              }
                            });
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppTheme.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_getMonthName(_selectedMonth)} $_selectedYear',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedMonth == 12) {
                                _selectedMonth = 1;
                                _selectedYear++;
                              } else {
                                _selectedMonth++;
                              }
                            });
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _ReportCard(
                          title: _translate('totalPendapatan'),
                          value: CurrencyFormatter.format(totalPendapatan),
                          icon: Icons.attach_money,
                          gradient: AppTheme.successGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportCard(
                          title: _translate('totalKasbonAktif'),
                          value: CurrencyFormatter.format(totalKasbonAktif),
                          icon: Icons.account_balance_wallet,
                          gradient: AppTheme.warningGradient,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ReportCard(
                          title: _translate('totalKasbonLunas'),
                          value: CurrencyFormatter.format(totalKasbonLunas),
                          icon: Icons.check_circle,
                          gradient: AppTheme.successGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportCard(
                          title: _translate('totalKasbonBaru'),
                          value: CurrencyFormatter.format(totalKasbonBaru),
                          icon: Icons.add_circle,
                          gradient: AppTheme.infoColor.toGradient(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ReportCard(
                    title: _translate('totalPelanggan'),
                    value: customerProvider.customers.length.toString(),
                    icon: Icons.people,
                    gradient: AppTheme.tealGradient,
                  ),
                  const SizedBox(height: 24),

                  // Top Customers
                  Text(
                    'Pelanggan Terbayar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildTopCustomersList(
                      paymentProvider,
                      customerProvider,
                      startOfMonth,
                      endOfMonth,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  Map<dynamic, double> _getTopCustomers(
    PaymentProvider paymentProvider,
    CustomerProvider customerProvider,
    DateTime startOfMonth,
    DateTime endOfMonth,
  ) {
    final Map<dynamic, double> customerPayments = {};

    final paymentsThisMonth = paymentProvider.payments.where((p) {
      return p.tanggal.isAfter(
            startOfMonth.subtract(const Duration(days: 1)),
          ) &&
          p.tanggal.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();

    for (final payment in paymentsThisMonth) {
      customerPayments[payment.customerId] =
          (customerPayments[payment.customerId] ?? 0) + payment.jumlah;
    }

    // Sort and return with customer names
    final sorted = customerPayments.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Map<dynamic, double> result = {};
    for (final entry in sorted) {
      final customer = customerProvider.getCustomerById(entry.key.toString());
      if (customer != null) {
        result[customer] = entry.value;
      }
    }

    return result;
  }

  Widget _buildTopCustomersList(
    PaymentProvider paymentProvider,
    CustomerProvider customerProvider,
    DateTime startOfMonth,
    DateTime endOfMonth,
  ) {
    final topCustomers = _getTopCustomers(
      paymentProvider,
      customerProvider,
      startOfMonth,
      endOfMonth,
    ).entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (topCustomers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Belum ada pembayaran',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: topCustomers.take(5).map((entry) {
        final customer = entry.key;
        final amount = entry.value;
        return _TopCustomerItem(name: customer.nama, amount: amount);
      }).toList(),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCustomerItem extends StatelessWidget {
  final String name;
  final double amount;

  const _TopCustomerItem({required this.name, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppTheme.primaryGradient),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  List<Color> toGradient() {
    return [this, this.withOpacity(0.7)];
  }
}
