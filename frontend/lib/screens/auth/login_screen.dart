import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoginMode = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Format the phone number to Iraqi format
    final formattedPhone = Validators.formatIraqiPhoneNumber(_phoneController.text.trim());

    if (_isLoginMode) {
      final success = await authProvider.login(
        formattedPhone,
        _passwordController.text,
      );

      if (success && mounted) {
        context.go('/home');
      }
    } else {
      // Split full name into first and last name
      final fullName = _fullNameController.text.trim();
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      final success = await authProvider.register(
        phoneNumber: formattedPhone,
        password: _passwordController.text,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (success && mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppConstants.backgroundColor,
                        AppConstants.surfaceColor,
                      ],
                    ),
                  ),
                ),
                
                // Main content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                          const SizedBox(height: 40),
              
                          // Logo and title
                          Column(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppConstants.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(60),
                                  border: Border.all(
                                    color: AppConstants.accentColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.spa,
                                  size: 60,
                color: AppConstants.accentColor,
              ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Welcome to Joulina',
                style: TextStyle(
                                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textPrimary,
                                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
                              Text(
                                _isLoginMode 
                                  ? 'Sign in to your account' 
                                  : 'Create your beauty profile',
                                style: const TextStyle(
                  fontSize: 16,
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
                              ),
                            ],
              ),
              
                          const SizedBox(height: 40),
              
                          // Form
              Form(
                key: _formKey,
                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Phone number field
                                CustomTextField(
                                  label: 'Phone Number',
                                  controller: _phoneController,
                                  isPhone: true,
                                  validator: Validators.validatePhoneNumber,
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Registration fields
                                if (!_isLoginMode) ...[
                                  CustomTextField(
                                    label: 'Full Name',
                                    controller: _fullNameController,
                                    validator: Validators.validateName,
                                  ),
                                  
                                  const SizedBox(height: 20),
                                ],
                    
                                // Password field
                                CustomTextField(
                                  label: 'Password',
                      controller: _passwordController,
                                  isPassword: true,
                                  validator: _isLoginMode 
                                    ? Validators.validatePassword 
                                    : Validators.validateNewPassword,
                                ),
                                
                                // Confirm password for registration
                                if (!_isLoginMode) ...[
                                  const SizedBox(height: 20),
                                  CustomTextField(
                                    label: 'Confirm Password',
                                    controller: _confirmPasswordController,
                                    isPassword: true,
                      validator: (value) {
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                        }
                        return null;
                      },
                                  ),
                                ],
                                
                                const SizedBox(height: 32),
                                
                                // Submit button
                                CustomButton(
                                  text: _isLoginMode ? 'Sign In' : 'Create Account',
                                  onPressed: authProvider.isLoading ? null : _submit,
                                  isLoading: authProvider.isLoading,
                    ),
                    
                    const SizedBox(height: 24),
                    
                                // Mode toggle
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isLoginMode 
                                        ? "Don't have an account? " 
                                        : "Already have an account? ",
                                      style: const TextStyle(
                                        color: AppConstants.textSecondary,
                        ),
                                    ),
                                    GestureDetector(
                                      onTap: _toggleMode,
                                      child: Text(
                                        _isLoginMode ? 'Sign Up' : 'Sign In',
                                        style: const TextStyle(
                                          color: AppConstants.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                                  ],
                    ),
                  ],
                ),
              ),
              
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              
                // Error message
                if (authProvider.hasError)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authProvider.error!,
                  style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
                    ),
                  ),
                
                // Loading overlay
                if (authProvider.isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: LoadingWidget(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
