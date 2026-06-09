import 'package:flutter/material.dart';
import 'reception_screen.dart';
import 'tests_screen.dart';
import 'patients_screen.dart';
import 'companies_screen.dart';
import 'doctor_screen.dart';
import 'reports_screen.dart';
import 'users_screen.dart';
import 'login_screen.dart';

class MainShell extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const MainShell({super.key, required this.currentUser});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _active = 'reception';
  bool _collapsed = false;

  // صلاحيات حسب الدور
  List<_NavItem> get _navItems {
    final role = widget.currentUser['role'];
    final all = [
      _NavItem('reception', Icons.local_hospital_rounded, 'الاستقبال', ['admin', 'reception']),
      _NavItem('doctor', Icons.vaccines_rounded, 'نتائج المعمل', ['admin', 'doctor']),
      _NavItem('tests', Icons.science_rounded, 'الفحوصات', ['admin']),
      _NavItem('patients', Icons.people_alt_rounded, 'المرضى', ['admin', 'reception']),
      _NavItem('companies', Icons.business_rounded, 'الشركات', ['admin']),
      _NavItem('reports', Icons.bar_chart_rounded, 'التقارير', ['admin']),
      _NavItem('users', Icons.manage_accounts_rounded, 'المستخدمين', ['admin']),
    ];
    return all.where((item) => item.roles.contains(role)).toList();
  }

  Widget _buildScreen() {
    switch (_active) {
      case 'reception': return ReceptionScreen(currentUser: widget.currentUser);
      case 'doctor': return DoctorScreen(currentUser: widget.currentUser);
      case 'tests': return const TestsScreen();
      case 'patients': return const PatientsScreen();
      case 'companies': return const CompaniesScreen();
      case 'reports': return const ReportsScreen();
      case 'users': return const UsersScreen();
      default: return ReceptionScreen(currentUser: widget.currentUser);
    }
  }

  @override
  void initState() {
    super.initState();
    // أول صفحة حسب الدور
    final role = widget.currentUser['role'];
    if (role == 'doctor') _active = 'doctor';
    else if (role == 'reception') _active = 'reception';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F7FF),
        body: Row(
          children: [
            _buildSidebar(),
            Expanded(child: _buildScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      width: _collapsed ? 72 : 230,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF01579B), Color(0xFF0277BD), Color(0xFF0288D1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [BoxShadow(color: Color(0x2501579B), blurRadius: 20, offset: Offset(4, 0))],
      ),
      child: Column(
        children: [
          // شعار
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
            child: Row(
              mainAxisAlignment: _collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 22),
                ),
                if (!_collapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('معمل الفادي', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                        Text('نظام إدارة المعمل', style: TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // بيانات المستخدم
          if (!_collapsed)
            Container(
              margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18, backgroundColor: Colors.white24,
                    child: Text(
                      (widget.currentUser['name'] as String? ?? 'م')[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.currentUser['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
                        Text(_roleLabel(widget.currentUser['role'] ?? ''), style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // قائمة التنقل
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                children: _navItems.map((item) {
                  final isActive = _active == item.key;
                  return GestureDetector(
                    onTap: () => setState(() => _active = item.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: EdgeInsets.symmetric(horizontal: _collapsed ? 0 : 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white24 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: _collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          Icon(item.icon, color: isActive ? Colors.white : Colors.white60, size: 22),
                          if (!_collapsed) ...[
                            const SizedBox(width: 12),
                            Expanded(child: Text(item.label, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, fontSize: 14, fontFamily: 'Cairo'))),
                            if (isActive) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // تسجيل خروج + طي
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: _collapsed ? 0 : 14, vertical: 11),
                    decoration: BoxDecoration(color: Colors.red.shade900.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: _collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                        if (!_collapsed) ...[
                          const SizedBox(width: 10),
                          const Text('تسجيل خروج', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _collapsed = !_collapsed),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                    child: Icon(_collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: Colors.white70, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'مدير النظام';
      case 'reception': return 'موظف استقبال';
      case 'doctor': return 'دكتور المعمل';
      default: return role;
    }
  }
}

class _NavItem {
  final String key;
  final IconData icon;
  final String label;
  final List<String> roles;
  const _NavItem(this.key, this.icon, this.label, this.roles);
}