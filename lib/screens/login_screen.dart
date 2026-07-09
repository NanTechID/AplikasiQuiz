import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/theme.dart';
import 'dosen/dashboard_dosen.dart';
import 'mahasiswa/dashboard_mahasiswa.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Login Controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;

  // Register Controllers
  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _registerObscure = true;
  String _selectedRole = 'mahasiswa'; // 'mahasiswa' | 'dosen'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.openColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signIn(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );

      if (!mounted) return;

      final user = authProvider.currentUser!;
      _showSuccessSnackBar('Welcome back, ${user.name}!');

      if (user.isDosen) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardDosen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardMahasiswa()),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll(RegExp(r'\[.*\]'), '').trim());
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signUp(
        name: _registerNameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      final user = authProvider.currentUser!;
      _showSuccessSnackBar('Account created! Welcome, ${user.name}.');

      if (user.isDosen) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardDosen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardMahasiswa()),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll(RegExp(r'\[.*\]'), '').trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.surfaceGradient : null,
          color: isDark ? null : AppTheme.lightBg,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Branding Header
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.buttonShadow,
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quiz Online',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Access your student or lecturer account',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Auth Card containing Tabs
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        width: 1,
                      ),
                      boxShadow: AppTheme.premiumShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Custom TabBar header
                        TabBar(
                          controller: _tabController,
                          indicatorColor: AppTheme.primary,
                          labelColor: AppTheme.primary,
                          unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
                          tabs: const [
                            Tab(text: 'Login', height: 60),
                            Tab(text: 'Register', height: 60),
                          ],
                        ),
                        const Divider(height: 1),
                        
                        // Tab Views
                        SizedBox(
                          height: 420,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLoginForm(isDark),
                              _buildRegisterForm(isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Form(
          key: _loginFormKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomTextField(
                  controller: _loginEmailController,
                  labelText: 'Email Address',
                  hintText: 'name@university.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: _loginPasswordController,
                  labelText: 'Password',
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _loginObscure,
                  suffixIcon: IconButton(
                    icon: Icon(_loginObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _loginObscure = !_loginObscure),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: 'Login',
                  isLoading: auth.isLoading,
                  onPressed: _handleLogin,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterForm(bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Form(
          key: _registerFormKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomTextField(
                  controller: _registerNameController,
                  labelText: 'Full Name',
                  hintText: 'John Doe',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: _registerEmailController,
                  labelText: 'Email Address',
                  hintText: 'name@university.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Please type a valid email';
                    return null;
                  },
                ),
                CustomTextField(
                  controller: _registerPasswordController,
                  labelText: 'Password',
                  hintText: 'Min 6 characters',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _registerObscure,
                  suffixIcon: IconButton(
                    icon: Icon(_registerObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _registerObscure = !_registerObscure),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                
                // Role Dropdown / Selector
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 22, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Text('I am registering as: ', style: TextStyle(fontSize: 15)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBg : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        elevation: 1,
                        underline: const SizedBox.shrink(),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'mahasiswa', child: Text('Student')),
                          DropdownMenuItem(value: 'dosen', child: Text('Lecturer')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomButton(
                  text: 'Create Account',
                  isLoading: auth.isLoading,
                  onPressed: _handleRegister,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
