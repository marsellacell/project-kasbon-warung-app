import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/customer.dart';
import '../../utils/currency_formatter.dart';
import '../../config/theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _translate(String key) {
    final Map<String, String> translations = {
      'customers': 'Pelanggan',
      'search': 'Cari',
      'addCustomer': 'Tambah Pelanggan',
      'noData': 'Tidak ada data',
      'saldoKasbon': 'Saldo Kasbon',
      'limitKredit': 'Limit Kredit',
      'delete': 'Hapus',
      'edit': 'Edit',
      'addKasbon': 'Tambah Kasbon',
      'riwayatKasbon': 'Riwayat Kasbon',
    };
    return translations[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final searchQuery = _searchController.text.toLowerCase();

    final filteredCustomers = customerProvider.customers
        .where(
          (c) =>
              c.nama.toLowerCase().contains(searchQuery) ||
              (c.hp?.toLowerCase().contains(searchQuery) ?? false),
        )
        .toList();

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
                _translate('customers'),
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
                    colors: AppTheme.tealGradient,
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '${_translate('search')}...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ),

          // Customer List
          customerProvider.isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : filteredCustomers.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _translate('noData'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final customer = filteredCustomers[index];
                      final activeKasbon = transactionProvider
                          .getActiveTransactionsByCustomer(customer.id)
                          .fold(0.0, (sum, t) => sum + t.nominal);
                      final isOverLimit =
                          customer.limitKredit > 0 &&
                          activeKasbon > customer.limitKredit;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CustomerCard(
                          customer: customer,
                          activeKasbon: activeKasbon,
                          isOverLimit: isOverLimit,
                          translate: _translate,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/customer-detail',
                            arguments: customer.id,
                          ),
                          onAddKasbon: () => Navigator.pushNamed(
                            context,
                            '/add-kasbon',
                            arguments: customer.id,
                          ),
                        ),
                      );
                    }, childCount: filteredCustomers.length),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-customer'),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: Text(_translate('addCustomer')),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final double activeKasbon;
  final bool isOverLimit;
  final String Function(String) translate;
  final VoidCallback onTap;
  final VoidCallback onAddKasbon;

  const _CustomerCard({
    required this.customer,
    required this.activeKasbon,
    required this.isOverLimit,
    required this.translate,
    required this.onTap,
    required this.onAddKasbon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverLimit
            ? Border.all(color: AppTheme.errorColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isOverLimit
                ? AppTheme.errorColor.withOpacity(0.1)
                : AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      customer.nama.isNotEmpty
                          ? customer.nama[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.nama,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            customer.hp ?? '-',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOverLimit
                                  ? AppTheme.errorLight
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 12,
                                  color: isOverLimit
                                      ? AppTheme.errorColor
                                      : AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  CurrencyFormatter.format(activeKasbon),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isOverLimit
                                        ? AppTheme.errorColor
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (customer.limitKredit > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Limit: ${CurrencyFormatter.format(customer.limitKredit)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'addKasbon') {
                      onAddKasbon();
                    } else if (value == 'detail') {
                      onTap();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'addKasbon',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_card,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(translate('addKasbon')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.history,
                              size: 18,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(translate('riwayatKasbon')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
