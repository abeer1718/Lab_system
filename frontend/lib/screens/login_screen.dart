import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final user = await ApiService.login(_userCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);
    if (user != null) {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => MainShell(currentUser: user)));
    } else {
      setState(() => _error = 'اسم المستخدم أو كلمة المرور غير صحيحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F7FF),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 420,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Color(0x1A0277BD), blurRadius: 30, offset: Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF01579B), Color(0xFF0288D1)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 38),
                        ),
                        const SizedBox(height: 16),
                        const Text('معمل الفادي', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                        // const Text('نظام إدارة المعمل', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF263238), fontFamily: 'Cairo')),
                          const SizedBox(height: 4),
                          const Text('أدخل بيانات حسابك للمتابعة', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontFamily: 'Cairo')),
                          const SizedBox(height: 24),
                          if (_error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontFamily: 'Cairo', fontSize: 13))),
                              ]),
                            ),
                          TextFormField(
                            controller: _userCtrl,
                            validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                            style: const TextStyle(fontFamily: 'Cairo'),
                            decoration: _dec('اسم المستخدم', Icons.person_outline),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                            style: const TextStyle(fontFamily: 'Cairo'),
                            decoration: _dec('كلمة المرور', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF90A4AE), size: 20),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0277BD),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('دخول', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
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

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF90A4AE)),
    prefixIcon: Icon(icon, color: const Color(0xFF90A4AE), size: 20),
    filled: true,
    fillColor: const Color(0xFFF0F7FF),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0F0FF), width: 1.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0F0FF), width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0277BD), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}