import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/hospital_account.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hospital_provider.dart';

class HospitalRegistrationScreen extends StatefulWidget {
  const HospitalRegistrationScreen({super.key});

  @override
  State<HospitalRegistrationScreen> createState() => _HospitalRegistrationScreenState();
}

class _HospitalRegistrationScreenState extends State<HospitalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _hospitalNameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _hospitalType = 'Multi-specialty';
  bool _isSubmitting = false;

  final List<String> _hospitalTypes = [
    'Multi-specialty',
    'Government Hospital',
    'Private Hospital',
    'Trauma & Emergency Center',
    'Clinic / Other',
  ];

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _regNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _adminNameController.dispose();
    _adminPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _fillDemoHospital() {
    _hospitalNameController.text = 'Ruby Hall Clinic (Emergency Center)';
    _regNumberController.text = 'MAH-PUN-MED-2024-8891';
    _hospitalType = 'Multi-specialty';
    _addressController.text = '40 Sassoon Road, Pune Station Area';
    _cityController.text = 'Pune';
    _stateController.text = 'Maharashtra';
    _pinCodeController.text = '411001';
    _phoneController.text = '+91 20 6645 5100';
    _emailController.text = 'emergency.pune@rubyhall.demo';
    _adminNameController.text = 'Suresh Nair (Hospital Admin)';
    _adminPhoneController.text = '+91 98220 54321';
    _passwordController.text = 'password123';
    _confirmPasswordController.text = 'password123';
    setState(() {});
  }

  Future<void> _handleHospitalRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match.'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      final hospital = HospitalAccount(
        id: 'HOSP-${DateTime.now().millisecondsSinceEpoch % 10000}',
        hospitalName: _hospitalNameController.text.trim(),
        registrationNumber: _regNumberController.text.trim(),
        hospitalType: _hospitalType,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        officialPhone: _phoneController.text.trim(),
        officialEmail: _emailController.text.trim(),
        adminName: _adminNameController.text.trim(),
        adminPhone: _adminPhoneController.text.trim(),
        verificationStatus: 'Verified', // Simulated Verified status for prototype
        createdAt: DateTime.now(),
      );

      final hospitalProvider = Provider.of<HospitalProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.registerHospital(
        hospitalData: hospital,
        password: _passwordController.text,
      );

      if (success && authProvider.hospitalUser != null) {
        await hospitalProvider.setCurrentHospital(authProvider.hospitalUser!);
      } else {
        await hospitalProvider.registerHospital(hospital);
      }
      authProvider.setSelectedRole(UserRole.doctor); // Uses hospital-side authentication

      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hospital registered successfully! Accessing Hospital Portal...'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pushReplacementNamed(context, '/doctor/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Registration'),
        actions: [
          TextButton(
            onPressed: _fillDemoHospital,
            child: const Text('Auto-fill Demo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hospital Emergency Network Registration',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Register your hospital or clinic to coordinate ambulances, scan patient QR codes, and manage doctors.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Hospital Details
                const Text(
                  '1. Hospital Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hospitalNameController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital / Healthcare Facility Name *',
                    prefixIcon: Icon(Icons.apartment_rounded),
                  ),
                  validator: (v) => Validators.validateRequired(v, 'Hospital Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital Registration / License Number *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => Validators.validateRequired(v, 'Registration Number'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _hospitalType,
                  decoration: const InputDecoration(
                    labelText: 'Hospital Type *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _hospitalTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _hospitalType = v);
                  },
                ),
                const SizedBox(height: 20),

                // Section 2: Location & Contact
                const Text(
                  '2. Location & Contact Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital Address *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) => Validators.validateRequired(v, 'Address'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City *'),
                        validator: (v) => Validators.validateRequired(v, 'City'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(labelText: 'State *'),
                        validator: (v) => Validators.validateRequired(v, 'State'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pinCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'PIN Code *',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  validator: (v) => Validators.validateRequired(v, 'PIN Code'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Hospital Phone *',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: Validators.validatePhone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Hospital Email *',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.validateEmail,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 3: Administrator & Security
                const Text(
                  '3. Hospital Administrator & Credentials',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adminNameController,
                        decoration: const InputDecoration(
                          labelText: 'Admin / Rep Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => Validators.validateRequired(v, 'Admin Name'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _adminPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Admin Contact *',
                          prefixIcon: Icon(Icons.phone_android_outlined),
                        ),
                        validator: Validators.validatePhone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleHospitalRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'COMPLETE HOSPITAL REGISTRATION',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
