import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/supabase.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/customer/customers_screen.dart';
import 'screens/customer/add_customer_screen.dart';
import 'screens/customer/customer_detail_screen.dart';
import 'screens/kasbon/kasbon_screen.dart';
import 'screens/kasbon/add_kasbon_screen.dart';
import 'screens/kasbon/kasbon_detail_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: 'Kasbon Warung',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,
            locale: settingsProvider.locale,
            home: const AuthWrapper(),
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) {
                  switch (settings.name) {
                    case '/login':
                      return const LoginScreen();
                    case '/register':
                      return const RegisterScreen();
                    case '/home':
                      return const MainScreen(initialIndex: 0);
                    case '/customers':
                      return const MainScreen(initialIndex: 1);
                    case '/kasbon':
                      return const MainScreen(initialIndex: 2);
                    case '/reports':
                      return const MainScreen(initialIndex: 3);
                    case '/settings':
                      return const MainScreen(initialIndex: 4);
                    case '/add-customer':
                      return const AddCustomerScreen();
                    case '/customer-detail':
                      final customerId = settings.arguments as String;
                      return CustomerDetailScreen(customerId: customerId);
                    case '/add-kasbon':
                      final customerId = settings.arguments as String?;
                      return AddKasbonScreen(preselectedCustomerId: customerId);
                    case '/kasbon-detail':
                      final transactionId = settings.arguments as String;
                      return KasbonDetailScreen(transactionId: transactionId);
                    case '/payment':
                      final args = settings.arguments;
                      if (args is String) {
                        return PaymentScreen(customerId: args);
                      } else if (args is Map) {
                        return PaymentScreen(
                          customerId: args['customerId'] as String?,
                          transactionId: args['transactionId'] as String?,
                        );
                      }
                      return const PaymentScreen();
                    default:
                      return const LoginScreen();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Wait for auth to initialize
    if (authProvider.isAuthenticated) {
      return const MainScreen();
    }

    return const LoginScreen();
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const CustomersScreen(),
    const KasbonScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home, color: Colors.white, size: 20),
              ),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppTheme.tealGradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people, color: Colors.white, size: 20),
              ),
              label: 'Pelanggan',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.receipt_long_outlined,
                color: Colors.grey.shade600,
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.warningGradient,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              label: 'Kasbon',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.successGradient,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: Colors.grey.shade600),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.settings,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
