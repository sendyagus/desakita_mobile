import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/services/auth_service.dart';
import 'package:desa_wisata/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:desa_wisata/widgets/auth_header.dart';
import 'package:desa_wisata/widgets/custom_text_field.dart';
import 'package:desa_wisata/widgets/social_login_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _normalizeIndonesianPhone(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    final withoutLeadingZero = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
    return '+62$withoutLeadingZero';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final phone = _normalizeIndonesianPhone(_phoneController.text);

      await AuthService.instance.signUp(
        name: _namaController.text.trim(),
        email: _emailController.text.trim(),
        phone: phone,
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Logout setelah registrasi agar user harus login manual
      await AuthService.instance.signOut();

      if (!mounted) return;

      // Tampilkan pesan sukses
      ErrorHandler.showSuccessSnackBar(
        context,
        'Registrasi berhasil! Silakan login dengan akun Anda.',
      );

      // Redirect ke halaman login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (error) {
      debugPrint('❌ FirebaseAuthException: ${error.code} ${error.message}');
      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getAuthErrorMessage(error),
      );
    } catch (error, stackTrace) {
      debugPrint('❌ Unexpected error: $error');
      debugPrint('❌ Stack trace: $stackTrace');
      ErrorHandler.showErrorSnackBar(
        context,
        'Registrasi gagal. Periksa koneksi internet Anda',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan gambar dan judul
            const AuthHeader(),

            // Form card
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              transform: Matrix4.translationValues(0, -24, 0),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Lengkap
                    _fieldLabel('Nama Lengkap'),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _namaController,
                      hintText: 'masukkan nama lengkap Anda',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email
                    _fieldLabel('Email'),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'masukkan email Anda',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(
                          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Nomor Telepon
                    _fieldLabel('Nomor Telepon'),
                    const SizedBox(height: 8),
                    _phoneField(),

                    const SizedBox(height: 16),

                    // Kata Sandi
                    _fieldLabel('Kata Sandi'),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'minimal 8 karakter',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi tidak boleh kosong';
                        }
                        if (value.length < 8) {
                          return 'Kata sandi minimal 8 karakter';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Konfirmasi Kata Sandi
                    _fieldLabel('Konfirmasi Kata Sandi'),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Konfirmasi',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi kata sandi tidak boleh kosong';
                        }
                        if (value != _passwordController.text) {
                          return 'Kata sandi tidak cocok';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Tombol Daftar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D5016),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Daftar',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider "atau masuk dengan"
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFFDDDDDD)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau masuk dengan',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0xFFDDDDDD)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tombol Google & Facebook
                    Row(
                      children: [
                        Expanded(
                          child: SocialLoginButton(
                            label: 'Google',
                            iconPath: 'assets/icon/google.jpg',
                            onPressed: () {
                              ErrorHandler.showInfoSnackBar(
                                context,
                                'Daftar dengan Google belum tersedia.',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SocialLoginButton(
                            label: 'Facebook',
                            iconPath: 'assets/icon/faceboook.jpg',
                            onPressed: () {
                              ErrorHandler.showInfoSnackBar(
                                context,
                                'Daftar dengan Facebook belum tersedia.',
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Link masuk
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun? ',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Masuk',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D5016),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF333333),
      ),
    );
  }

  Widget _phoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Kode negara
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFDDDDDD), width: 1),
              ),
            ),
            child: Text(
              '+62',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          // Input nomor
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: '812 3456 7890',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor telepon tidak boleh kosong';
                }
                final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digitsOnly.length < 9) {
                  return 'Nomor telepon terlalu pendek';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
