import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/payment_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../models/transaction.dart';
import '../../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final customerProvider = context.read<CustomerProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    await Future.wait([
      customerProvider.fetchCustomers(),
      transactionProvider.fetchTransactions(),
      paymentProvider.fetchPayments(),
    ]);
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  String _translate(String key) {
    final Map<String, String> translations = {
      'home': 'Beranda',
      'totalKasbon': 'Total Kasbon Aktif',
      'totalCustomers': 'Total Pelanggan',
      'pendapatanBulanIni': 'Pendapatan Bulan Ini',
      'pelangganTeraktif': 'Pelanggan Teraktif',
      'kasbon': 'Kasbon',
      'addCustomer': 'Tambah Pelanggan',
      'addKasbon': 'Tambah Kasbon',
      'riwayatKasbon': 'Riwayat Kasbon',
      'noData': 'Tidak ada data',
      'active': 'Aktif',
      'paid': 'Lunas',
      'overdue': 'Jatuh Tempo',
      'welcome': 'Selamat Datang',
      'quickActions': 'Aksi Cepat',
    };
    return translations[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;
    final transactions = context.watch<TransactionProvider>().transactions;
    final payments = context.watch<PaymentProvider>().payments;

    // Calculate stats
    final activeTransactions = transactions
        .where((t) => t.status == TransactionStatus.active)
        .toList();
    final totalKasbon = activeTransactions.fold(
      0.0,
      (sum, t) => sum + t.nominal,
    );

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final pendapatanBulanIni = payments
        .where(
          (p) =>
              p.tanggal.isAfter(startOfMonth) ||
              p.tanggal.isAtSameMomentAs(startOfMonth),
        )
        .fold(0.0, (sum, p) => sum + p.jumlah);

    // Find most active customer
    final customerCounts = <String, int>{};
    for (final t in transactions) {
      customerCounts[t.customerId] = (customerCounts[t.customerId] ?? 0) + 1;
    }
    String? mostActiveCustomerName;
    int maxCount = 0;
    customerCounts.forEach((customerId, count) {
      if (count > maxCount) {
        maxCount = count;
        final customer = customers.where((c) => c.id == customerId).firstOrNull;
        mostActiveCustomerName = customer?.nama;
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Gradient App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _translate('home'),
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

            // Stats Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Row 1
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: _translate('totalKasbon'),
                            value: CurrencyFormatter.format(totalKasbon),
                            icon: Icons.account_balance_wallet,
                            gradient: AppTheme.primaryGradient,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: _translate('totalCustomers'),
                            value: customers.length.toString(),
                            icon: Icons.people,
                            gradient: AppTheme.tealGradient,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: _translate('pendapatanBulanIni'),
                            value: CurrencyFormatter.format(pendapatanBulanIni),
                            icon: Icons.trending_up,
                            gradient: AppTheme.successGradient,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: _translate('pelangganTeraktif'),
                            value: mostActiveCustomerName ?? '-',
                            icon: Icons.star,
                            gradient: AppTheme.warningGradient,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translate('quickActions'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.person_add,
                            label: _translate('addCustomer'),
                            color: AppTheme.primaryColor,
                            onTap: () =>
                                Navigator.pushNamed(context, '/add-customer'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.add_card,
                            label: _translate('addKasbon'),
                            color: AppTheme.secondaryColor,
                            onTap: () =>
                                Navigator.pushNamed(context, '/add-kasbon'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.payment,
                            label: _translate('payment'),
                            color: AppTheme.successColor,
                            onTap: () =>
                                Navigator.pushNamed(context, '/payment'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent Transactions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _translate('riwayatKasbon'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                      child: transactions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _translate('noData'),
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: transactions.take(5).map((transaction) {
                                final customer = customers
                                    .where(
                                      (c) => c.id == transaction.customerId,
                                    )
                                    .firstOrNull;
                                return _TransactionItem(
                                  customerName: customer?.nama ?? 'Unknown',
                                  itemName: transaction.namaBarang,
                                  amount: transaction.nominal,
                                  status: transaction.status,
                                  translate: _translate,
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String customerName;
  final String itemName;
  final double amount;
  final TransactionStatus status;
  final String Function(String) translate;

  const _TransactionItem({
    required this.customerName,
    required this.itemName,
    required this.amount,
    required this.status,
    required this.translate,
  });

  Color _getStatusColor() {
    switch (status) {
      case TransactionStatus.active:
        return AppTheme.warningColor;
      case TransactionStatus.paid:
        return AppTheme.successColor;
      case TransactionStatus.overdue:
        return AppTheme.errorColor;
    }
  }

  String _getStatusText() {
    switch (status) {
      case TransactionStatus.active:
        return translate('active');
      case TransactionStatus.paid:
        return translate('paid');
      case TransactionStatus.overdue:
        return translate('overdue');
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case TransactionStatus.active:
        return Icons.access_time;
      case TransactionStatus.paid:
        return Icons.check_circle;
      case TransactionStatus.overdue:
        return Icons.warning;
    }
  }

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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  itemName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
