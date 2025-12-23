import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../services/mock_firebase_service.dart';
import '../models/user_profile.dart';
import 'home_screen.dart';

class RegistrationWizard extends StatefulWidget {
  const RegistrationWizard({super.key});

  @override
  State<RegistrationWizard> createState() => _RegistrationWizardState();
}

class _RegistrationWizardState extends State<RegistrationWizard> {
  final PageController _pageController = PageController();
  final MockFirebaseService _firebase = MockFirebaseService.instance;
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Step 1: National ID & Phone
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Step 2: OTP
  final _otpController = TextEditingController();
  String? _sentOtp;
  
  // Step 3: Personal Details
  final _nameArabicController = TextEditingController();
  final _nameEnglishController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _selectedGovernorate;
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  
  // Step 4: PIN
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  @override
  void dispose() {
    _pageController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameArabicController.dispose();
    _nameEnglishController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);
    try {
      _sentOtp = await _firebase.sendOTP(_phoneController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${_phoneController.text}\\nCode: $_sentOtp'),
          backgroundColor: Colors.green,
        ),
      );
      _nextStep();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    setState(() => _isLoading = true);
    try {
      final isValid = await _firebase.verifyOTP(
        _phoneController.text,
        _otpController.text,
      );
      
      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verified!'), backgroundColor: Colors.green),
        );
        _nextStep();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeRegistration() async {
    setState(() => _isLoading = true);
    try {
      final profileData = {
        'fullNameArabic': _nameArabicController.text,
        'fullNameEnglish': _nameEnglishController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'dateOfBirth': _dateOfBirth!.toIso8601String(),
        'governorate': _selectedGovernorate!,
        'city': _cityController.text,
        'street': _streetController.text,
        'kycStatus': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firebase.registerUser(
        nationalId: _nationalIdController.text,
        phoneNumber: _phoneController.text,
        pin: _pinController.text,
        profileData: profileData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registration successful! Welcome to Egyptian Banking!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a moment for user to see the success message
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Registration failed. Please try again.\n${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: theme.colorScheme.surfaceVariant,
          ),
          const SizedBox(height: 16),
          
          // Step Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepIndicator(0, 'ID & Phone'),
                _buildStepIndicator(1, 'Verify'),
                _buildStepIndicator(2, 'Details'),
                _buildStepIndicator(3, 'PIN'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceVariant,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'National ID & Phone Number',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your Egyptian National ID and phone number',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _nationalIdController,
            decoration: const InputDecoration(
              labelText: 'National ID',
              hintText: '14 digits',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
            ],
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+20 10XXXXXXXX',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : () {
                if (!MockFirebaseService.isValidEgyptianNationalId(_nationalIdController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid National ID format')),
                  );
                  return;
                }
                if (!MockFirebaseService.isValidEgyptianPhone(_phoneController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid Egyptian phone number')),
                  );
                  return;
                }
                _sendOTP();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send OTP'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Phone Number',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to ${_phoneController.text}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _otpController,
            decoration: const InputDecoration(
              labelText: 'OTP Code',
              hintText: '6 digits',
              prefixIcon: Icon(Icons.sms),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
          ),
          const SizedBox(height: 16),
          
          Center(
            child: TextButton(
              onPressed: _sendOTP,
              child: const Text('Resend OTP'),
            ),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _verifyOTP,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _nameArabicController,
            decoration: const InputDecoration(
              labelText: 'Full Name (Arabic)',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _nameEnglishController,
            decoration: const InputDecoration(
              labelText: 'Full Name (English)',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email (Optional)',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date of Birth'),
            subtitle: Text(
              _dateOfBirth != null
                  ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                  : 'Select date',
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _dateOfBirth = date);
              }
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedGovernorate,
            decoration: const InputDecoration(
              labelText: 'Governorate',
              prefixIcon: Icon(Icons.location_city),
              border: OutlineInputBorder(),
            ),
            items: EgyptianGovernorates.all.map((gov) {
              return DropdownMenuItem(value: gov, child: Text(gov));
            }).toList(),
            onChanged: (value) => setState(() => _selectedGovernorate = value),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Street Address',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_nameArabicController.text.isEmpty ||
                    _nameEnglishController.text.isEmpty ||
                    _dateOfBirth == null ||
                    _selectedGovernorate == null ||
                    _cityController.text.isEmpty ||
                    _streetController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }
                _nextStep();
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create PIN',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a 6-digit PIN to secure your account',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _pinController,
            decoration: const InputDecoration(
              labelText: 'PIN',
              hintText: '6 digits',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _confirmPinController,
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              hintText: '6 digits',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : () {
                if (_pinController.text.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be 6 digits')),
                  );
                  return;
                }
                if (_pinController.text != _confirmPinController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PINs do not match')),
                  );
                  return;
                }
                _completeRegistration();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Complete Registration'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
