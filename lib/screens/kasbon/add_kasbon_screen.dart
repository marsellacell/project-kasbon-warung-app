import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/customer.dart';
import '../../config/theme.dart';

class AddKasbonScreen extends StatefulWidget {
  final String? preselectedCustomerId;

  const AddKasbonScreen({super.key, this.preselectedCustomerId});

  @override
  State<AddKasbonScreen> createState() => _AddKasbonScreenState();
}

class _AddKasbonScreenState extends State<AddKasbonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaBarangController = TextEditingController();
  final _nominalController = TextEditingController();
  final _deskripsiController = TextEditingController();

  Customer? _selectedCustomer;
  DateTime _tanggal = DateTime.now();
  DateTime? _tenggat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedCustomerId != null) {
        final customerProvider = context.read<CustomerProvider>();
        final customer = customerProvider.getCustomerById(
          widget.preselectedCustomerId!,
        );
        if (customer != null) {
          setState(() {
            _selectedCustomer = customer;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _namaBarangController.dispose();
    _nominalController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isTenggat) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isTenggat
          ? (_tenggat ?? DateTime.now().add(const Duration(days: 7)))
          : _tanggal,
      firstDate: isTenggat ? DateTime.now() : DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isTenggat) {
          _tenggat = picked;
        } else {
          _tanggal = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pelanggan terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final transactionProvider = context.read<TransactionProvider>();
    final success = await transactionProvider.addTransaction(
      customerId: _selectedCustomer!.id,
      namaBarang: _namaBarangController.text.trim(),
      nominal: double.parse(_nominalController.text),
      deskripsi: _deskripsiController.text.trim().isEmpty
          ? null
          : _deskripsiController.text.trim(),
      tanggal: _tanggal,
      tenggat: _tenggat,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transactionProvider.error ?? 'Gagal menambahkan kasbon',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _translate(String key) {
    final Map<String, String> translations = {
      'addKasbon': 'Tambah Kasbon',
      'namaPelanggan': 'Nama Pelanggan',
      'namaBarang': 'Nama Barang',
      'nominal': 'Nominal',
      'deskripsi': 'Deskripsi',
      'tanggal': 'Tanggal',
      'tenggat': 'Tenggat',
      'save': 'Simpan',
      'cancel': 'Batal',
      'selectCustomer': 'Pilih Pelanggan',
    };
    return translations[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('addKasbon')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.warningGradient,
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
                      color: AppTheme.warningColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Customer Dropdown
                    DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
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
                      hint: Text(_translate('selectCustomer')),
                      items: customerProvider.customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer,
                          child: Text(customer.nama),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomer = value;
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

                    // Nama Barang
                    TextFormField(
                      controller: _namaBarangController,
                      decoration: InputDecoration(
                        labelText: _translate('namaBarang'),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppTheme.warningColor,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama barang harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nominal
                    TextFormField(
                      controller: _nominalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _translate('nominal'),
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
                          return 'Nominal harus diisi';
                        }
                        final nominal = double.tryParse(value);
                        if (nominal == null || nominal <= 0) {
                          return 'Nominal harus angka positif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: _translate('deskripsi'),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
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
                    const SizedBox(height: 16),

                    // Tanggal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _translate('tanggal'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_tanggal.day}/${_tanggal.month}/${_tanggal.year}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _selectDate(context, false),
                            icon: const Icon(
                              Icons.edit,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tenggat
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.event,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _translate('tenggat'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tenggat != null
                                      ? '${_tenggat!.day}/${_tenggat!.month}/${_tenggat!.year}'
                                      : 'Belum ditentukan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _tenggat != null
                                        ? null
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_tenggat != null)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _tenggat = null;
                                });
                              },
                            ),
                          IconButton(
                            onPressed: () => _selectDate(context, true),
                            icon: const Icon(
                              Icons.edit,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
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
                        backgroundColor: AppTheme.warningColor,
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
