import 'package:flutter/material.dart';
import 'dart:html' as html; // للطباعة
import 'reception_screen.dart';
import 'tests_screen.dart';
import 'patients_screen.dart';
import 'companies_screen.dart';
import 'doctor_screen.dart';
import 'reports_screen.dart';
import 'users_screen.dart';
import 'login_screen.dart';
import 'shifts_screen.dart';
import '../services/api_service.dart';

class MainShell extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const MainShell({super.key, required this.currentUser});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _active = 'reception';
  bool _collapsed = false;
  Map<String, dynamic>? _openSession; // الوردية المفتوحة حالياً
  bool _loadingSession = true;

  @override
  void initState() {
    super.initState();
    final role = widget.currentUser['role'];
    if (role == 'doctor') _active = 'doctor';
    else if (role == 'reception') _active = 'reception';
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await ApiService.getOpenSession(
        widget.currentUser['id'] as int);
    setState(() {
      _openSession = session;
      _loadingSession = false;
    });
  }

  // ── صلاحيات حسب الدور ──────────────────────────
  List<_NavItem> get _navItems {
    final role = widget.currentUser['role'];
    final all = [
      _NavItem('reception', Icons.local_hospital_rounded, 'الاستقبال',    ['admin', 'reception']),
      _NavItem('doctor',    Icons.vaccines_rounded,        'نتائج المعمل', ['admin', 'doctor']),
      _NavItem('tests',     Icons.science_rounded,         'الفحوصات',     ['admin']),
      // _NavItem('patients',  Icons.people_alt_rounded,      'المرضى',       ['admin', 'reception']),
      _NavItem('companies', Icons.business_rounded,        'الشركات',      ['admin']),
      _NavItem('reports',   Icons.bar_chart_rounded,       'التقارير',     ['admin']),
      _NavItem('users',     Icons.manage_accounts_rounded, 'المستخدمين',   ['admin']),
      _NavItem('shifts',    Icons.alarm_rounded,           'الورديات',     ['admin']),
    ];
    return all.where((item) => item.roles.contains(role)).toList();
  }

  Widget _buildScreen() {
    switch (_active) {
      case 'reception': return ReceptionScreen(
          currentUser: widget.currentUser,
          openSession: _openSession,
          onSessionChanged: _loadSession,
        );
      case 'doctor':    return DoctorScreen(currentUser: widget.currentUser);
      case 'tests':     return const TestsScreen();
      case 'patients':  return const PatientsScreen();
      case 'companies': return const CompaniesScreen();
      case 'reports':   return const ReportsScreen();
      case 'users':     return const UsersScreen();
      case 'shifts':    return const ShiftsScreen();
      default:          return ReceptionScreen(
          currentUser: widget.currentUser,
          openSession: _openSession,
          onSessionChanged: _loadSession,
        );
    }
  }

  // ── فتح وردية ─────────────────────────────────
  Future<void> _openShift() async {
    final shifts = List<Map<String, dynamic>>.from(
        await ApiService.getShifts());

    if (shifts.isEmpty) {
      _showSnack('لا توجد ورديات معرفة. يرجى إضافة ورديات أولاً.', isError: true);
      return;
    }

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final autoShift = await ApiService.getShiftForTime(timeStr);

    Map<String, dynamic>? selectedShift = autoShift ?? shifts.first;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 420,
              child: SingleChildScrollView( // لحماية الـ Dialog من الـ overflow الرأسي على الهواتف
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.play_circle_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('بداية وردية', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                          Text('اختر الوردية لبدء العمل', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo')),
                        ]),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx, false)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.access_time_rounded, color: Color(0xFF0277BD), size: 20),
                          const SizedBox(width: 10),
                          Expanded( // منع الـ overflow الأفقي عند عرض الوقت والتاريخ
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('الوقت الحالي', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF90A4AE))),
                              Text(
                                '${now.day}/${now.month}/${now.year}  $timeStr',
                                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, color: Color(0xFF263238)),
                              ),
                            ]),
                          ),
                          if (autoShift != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                              child: const Text('تلقائي', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text('الوردية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF546E7A))),
                      ),
                      const SizedBox(height: 8),
                      ...shifts.map((s) {
                        final isSelected = selectedShift?['id'] == s['id'];
                        final color = Color(s['color'] as int? ?? 0xFF0277BD);
                        return GestureDetector(
                          onTap: () => setS(() => selectedShift = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF0F7FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? color : const Color(0xFFE0F0FF), width: isSelected ? 2 : 1.5),
                            ),
                            child: Row(children: [
                              Container(
                                width: 10, height: 36,
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(s['name'], style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, color: isSelected ? color : const Color(0xFF263238))),
                                  Text('${s['start_time']} - ${s['end_time']}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF90A4AE))),
                                ]),
                              ),
                              if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 22),
                            ]),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF546E7A),
                            side: const BorderSide(color: Color(0xFFE0F0FF), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          ),
                          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: selectedShift == null ? null : () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('بدء الوردية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && selectedShift != null) {
      await ApiService.openShiftSession({
        'user_id': widget.currentUser['id'],
        'user_name': widget.currentUser['name'],
        'shift_id': selectedShift!['id'],
        'shift_name': selectedShift!['name'],
        'start_time': DateTime.now().toIso8601String(),
        'status': 'open',
      });
      await _loadSession();
      _showSnack('تم فتح وردية "${selectedShift!['name']}" بنجاح ✓');
    }
  }

  // ── إغلاق وردية ───────────────────────────────
  Future<void> _closeShift() async {
    if (_openSession == null) return;

    final visits = List<Map<String, dynamic>>.from(
        await ApiService.getVisitsBySession(_openSession!['id'] as int));

    double totalCash   = 0, totalBank  = 0, totalFwry  = 0,
           totalOkash  = 0, totalMycash = 0, grandTotal = 0;
    int    countCash   = 0, countBank  = 0, countFwry  = 0,
           countOkash  = 0, countMycash = 0;

    for (final v in visits) {
      final amount = (v['total'] as num? ?? 0).toDouble();
      grandTotal += amount;
      switch (v['payment_method'] as String? ?? '') {
        case 'cash':   totalCash   += amount; countCash++;   break;
        case 'bank':   totalBank   += amount; countBank++;   break;
        case 'fwry':   totalFwry   += amount; countFwry++;   break;
        case 'okash':  totalOkash  += amount; countOkash++;  break;
        case 'mycash': totalMycash += amount; countMycash++; break;
      }
    }

    final startDt = DateTime.tryParse(_openSession!['start_time'] ?? '') ?? DateTime.now();
    final endDt = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 500,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)]),
                ),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('نهاية وردية: ${_openSession!['shift_name']}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                      Text('${_fmtDt(startDt)} ← ${_fmtDt(endDt)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo')),
                    ]),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx, false)),
                ]),
              ),
              Flexible( // استخدمنا Flexible مع SingleChildScrollView لمنع الـ bottom overflow تماماً في نافذة الإغلاق
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0277BD), Color(0xFF01579B)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _statCol('إجمالي الزيارات', '${visits.length}', Icons.receipt_long_rounded),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _statCol('إجمالي الإيرادات', '${grandTotal.toStringAsFixed(0)} ج', Icons.payments_rounded),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('تفصيل طرق الدفع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF263238))),
                    ),
                    const SizedBox(height: 10),
                    _payRow('كاش',      Icons.payments_outlined,          const Color(0xFF2E7D32), countCash,   totalCash),
                    _payRow('بنكك',     Icons.account_balance_outlined,   const Color(0xFF0277BD), countBank,   totalBank),
                    _payRow('فوري',     Icons.account_balance_outlined,   const Color(0xFF7B1FA2), countFwry,   totalFwry),
                    _payRow('اوكاش',    Icons.account_balance_outlined,   const Color(0xFFF57C00), countOkash,  totalOkash),
                    _payRow('ماي كاش',  Icons.phone_iphone_outlined,      const Color(0xFF0097A7), countMycash, totalMycash),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _doPrint(
                            sessionName: _openSession!['shift_name'],
                            userName: _openSession!['user_name'],
                            startDt: startDt, endDt: endDt,
                            visits: visits,
                            totalCash: totalCash, countCash: countCash,
                            totalBank: totalBank, countBank: countBank,
                            totalFwry: totalFwry, countFwry: countFwry,
                            totalOkash: totalOkash, countOkash: countOkash,
                            totalMycash: totalMycash, countMycash: countMycash,
                            grandTotal: grandTotal,
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('طباعة التقرير', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0277BD),
                          side: const BorderSide(color: Color(0xFF0277BD), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('إغلاق الوردية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await ApiService.closeShiftSession(
        _openSession!['id'] as int,
        DateTime.now().toIso8601String(),
      );
      await _loadSession();
      _showSnack('تم إغلاق الوردية بنجاح');
    }
  }

  // ── Helpers ────────────────────────────────────
  String _fmtDt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Widget _statCol(String label, String value, IconData icon) => Column(children: [
    Icon(icon, color: Colors.white70, size: 20),
    const SizedBox(height: 6),
    Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 18)),
    Text(label, style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 11)),
  ]);

  Widget _payRow(String label, IconData icon, Color color, int count, double total) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: color)),
        const Spacer(),
        Text('$count زيارة', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF90A4AE))),
        const SizedBox(width: 16),
        Text('${total.toStringAsFixed(0)} ج', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 15, color: color)),
      ]),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF1B5E20),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── طباعة تقرير الوردية ───────────────────────
  void _doPrint({
    required String sessionName, required String userName,
    required DateTime startDt, required DateTime endDt,
    required List<Map<String, dynamic>> visits,
    required double totalCash, required int countCash,
    required double totalBank, required int countBank,
    required double totalFwry, required int countFwry,
    required double totalOkash, required int countOkash,
    required double totalMycash, required int countMycash,
    required double grandTotal,
  }) {
    String payBlock(String label, int count, double total, String color) {
      if (count == 0) return '';
      return '''
        <div class="pay-row" style="border-right: 4px solid $color">
          <span class="pay-label">$label</span>
          <span class="pay-count">$count زيارة</span>
          <span class="pay-total" style="color:$color">${total.toStringAsFixed(0)} ج</span>
        </div>''';
    }

    final rows = visits.map((v) {
      final dt = DateTime.tryParse(v['date'] ?? '') ?? DateTime.now();
      final pm = _payLabel(v['payment_method'] ?? '');
      return '''<tr>
        <td>${v['patient_name'] ?? ''}</td>
        <td>${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}</td>
        <td>$pm</td>
        <td style="font-weight:800;color:#0277BD">${(v['total'] as num? ?? 0).toStringAsFixed(0)} ج</td>
      </tr>''';
    }).join('\n');

    final html_ = '''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>تقرير وردية - $sessionName</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap');
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Cairo',sans-serif;background:#fff;color:#263238;padding:28px;direction:rtl}
.header{display:flex;justify-content:space-between;align-items:center;border-bottom:3px solid #0277BD;padding-bottom:14px;margin-bottom:20px}
.lab-name{font-size:22px;font-weight:800;color:#0277BD}
.lab-sub{font-size:12px;color:#546E7A;margin-top:3px}
.meta{display:flex;gap:20px;background:#F0F7FF;border-radius:10px;padding:12px 16px;margin-bottom:18px}
.meta-item label{font-size:10px;color:#90A4AE;display:block}
.meta-item span{font-size:13px;font-weight:700}
.summary{display:flex;background:linear-gradient(135deg,#0277BD,#01579B);border-radius:12px;padding:16px;margin-bottom:18px;color:#fff;gap:0}
.sum-col{flex:1;text-align:center}
.sum-col .val{font-size:22px;font-weight:800}
.sum-col .lbl{font-size:11px;opacity:.8;margin-top:2px}
.divider{width:1px;background:rgba(255,255,255,.2)}
.section-title{font-size:13px;font-weight:800;color:#263238;margin-bottom:8px}
.pay-row{display:flex;align-items:center;gap:12px;background:#f9f9f9;border-radius:8px;padding:10px 14px;margin-bottom:7px}
.pay-label{font-weight:700;flex:1}
.pay-count{font-size:11px;color:#90A4AE}
.pay-total{font-weight:800;font-size:15px;min-width:80px;text-align:left}
table{width:100%;border-collapse:collapse;margin-top:16px}
thead tr{background:#0277BD;color:#fff}
thead th{padding:10px 14px;font-size:12px;text-align:right}
tbody tr:nth-child(even){background:#F0F7FF}
tbody td{padding:9px 14px;font-size:12px;border-bottom:1px solid #E0F0FF}
.footer{margin-top:20px;padding-top:14px;border-top:1px solid #E0F0FF;text-align:center;font-size:11px;color:#90A4AE}
@media print{body{padding:12px}}
</style>
</head>
<body>
<div class="header">
  <div><div class="lab-name">مختبر الفادي</div><div class="lab-sub">تقرير إغلاق وردية</div></div>
  <div style="font-size:11px;color:#90A4AE">طُبع: ${_fmtDt(endDt)}</div>
</div>
<div class="meta">
  <div class="meta-item"><label>الوردية</label><span>$sessionName</span></div>
  <div class="meta-item"><label>الموظف</label><span>$userName</span></div>
  <div class="meta-item"><label>بداية الوردية</label><span>${_fmtDt(startDt)}</span></div>
  <div class="meta-item"><label>نهاية الوردية</label><span>${_fmtDt(endDt)}</span></div>
</div>
<div class="summary">
  <div class="sum-col"><div class="val">${visits.length}</div><div class="lbl">إجمالي الزيارات</div></div>
  <div class="divider"></div>
  <div class="sum-col"><div class="val">${grandTotal.toStringAsFixed(0)} ج</div><div class="lbl">إجمالي الإيرادات</div></div>
</div>
<div class="section-title">تفصيل طرق الدفع</div>
${payBlock('كاش',     countCash,   totalCash,   '#2E7D32')}
${payBlock('بنكك',    countBank,   totalBank,   '#0277BD')}
${payBlock('فوري',    countFwry,   totalFwry,   '#7B1FA2')}
${payBlock('اوكاش',   countOkash,  totalOkash,  '#F57C00')}
${payBlock('ماي كاش', countMycash, totalMycash, '#0097A7')}
<div class="section-title" style="margin-top:18px">تفصيل الزيارات</div>
<table>
  <thead><tr><th>المريض</th><th>الوقت</th><th>طريقة الدفع</th><th>المبلغ</th></tr></thead>
  <tbody>$rows</tbody>
</table>
<div class="footer">مختبر الفادي — نظام إدارة المعمل</div>
<script>window.onload=function(){window.print()}</script>
</body></html>''';

    final blob = html.Blob([html_], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  String _payLabel(String m) {
    switch (m) {
      case 'cash':   return 'كاش';
      case 'bank':   return 'بنكك';
      case 'fwry':   return 'فوري';
      case 'okash':  return 'اوكاش';
      case 'mycash': return 'ماي كاش';
      default:       return m;
    }
  }

  // ══════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // تم رفع القيمة إلى 950 لضمان مساحة مريحة على لابتوبات الشاشات المتوسطة والصغيرة
    final isMobile = MediaQuery.of(context).size.width < 950;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F7FF),
        appBar: isMobile
            ? AppBar(
                title: const Text('معمل الفادي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 16)),
                backgroundColor: const Color(0xFF01579B),
                foregroundColor: Colors.white,
                elevation: 0,
              )
            : null,
        drawer: isMobile ? Drawer(child: _buildSidebar(isDrawer: true)) : null,
        body: Row(
          children: [
            if (!isMobile) _buildSidebar(isDrawer: false),
            Expanded(
              child: ClipRect( // يضمن عدم تمدد الشاشات الداخلية خارج إطار الـ Expanded المخصص لها
                child: _buildScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({required bool isDrawer}) {
    final hasSession = _openSession != null;
    final currentWidth = isDrawer ? 240.0 : (_collapsed ? 72.0 : 230.0);
    final showFullContent = isDrawer || !_collapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      width: currentWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF01579B), Color(0xFF0277BD), Color(0xFF0288D1)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        boxShadow: [BoxShadow(color: Color(0x2501579B), blurRadius: 20, offset: Offset(4, 0))],
      ),
      child: Column(children: [
        // شعار المعمل
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
          child: Row(
            mainAxisAlignment: showFullContent ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 22)),
              if (showFullContent) ...[
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('معمل الفادي', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                  // Text('نظام إدارة المعمل', style: TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Cairo')),
                ])),
              ],
            ],
          ),
        ),

        // بيانات المستخدم
        if (showFullContent)
          Container(
            margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              CircleAvatar(radius: 18, backgroundColor: Colors.white24,
                child: Text((widget.currentUser['name'] as String? ?? 'م')[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Cairo'))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.currentUser['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Cairo'), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_roleLabel(widget.currentUser['role'] ?? ''), style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Cairo')),
              ])),
            ]),
          ),

        // ── زر الوردية ────────────────────────
        if (['admin', 'reception'].contains(widget.currentUser['role']))
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: _loadingSession
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2)))
                : GestureDetector(
                    onTap: () async {
                      if (isDrawer) Navigator.pop(context);
                      hasSession ? _closeShift() : _openShift();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: showFullContent ? 12 : 0, vertical: 11),
                      decoration: BoxDecoration(
                        color: hasSession ? const Color(0x33EF4444) : const Color(0x332E7D32),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasSession ? const Color(0x88EF4444) : const Color(0x882E7D32),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: showFullContent ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasSession ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
                            color: hasSession ? const Color(0xFFFF7070) : const Color(0xFF81C784),
                            size: 22,
                          ),
                          if (showFullContent) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  hasSession ? 'إنهاء الوردية' : 'بداية وردية',
                                  style: TextStyle(
                                    fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13,
                                    color: hasSession ? const Color(0xFFFF7070) : const Color(0xFF81C784),
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                if (hasSession)
                                  Text(
                                    _openSession!['shift_name'] ?? '',
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white54),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                              ]),
                            ),
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: hasSession ? const Color(0xFF4CAF50) : Colors.white30,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),

        // قائمة العناصر
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: ListView(
              padding: EdgeInsets.zero,
              children: _navItems.map((item) {
                final isActive = _active == item.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _active = item.key);
                    if (isDrawer) Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: EdgeInsets.symmetric(horizontal: showFullContent ? 14 : 0, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white24 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: showFullContent ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, color: isActive ? Colors.white : Colors.white60, size: 22),
                        if (showFullContent) ...[
                          const SizedBox(width: 12),
                          Expanded(child: Text(item.label, style: TextStyle(
                            color: isActive ? Colors.white : Colors.white70,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14, fontFamily: 'Cairo',
                          ), maxLines: 1, overflow: TextOverflow.ellipsis)),
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

        // تسجيل الخروج وسهم التصغير
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: showFullContent ? 14 : 0, vertical: 11),
                decoration: BoxDecoration(color: Colors.red.shade900.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: showFullContent ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                    if (showFullContent) ...[
                      const SizedBox(width: 10),
                      const Expanded(child: Text('تسجيل خروج', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ],
                ),
              ),
            ),
            // if (!isDrawer) ...[
            //   const SizedBox(height: 8),
            //   GestureDetector(
            //     onTap: () => setState(() => _collapsed = !_collapsed),
            //     child: Container(
            //       padding: const EdgeInsets.all(10),
            //       decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
            //       child: Icon(_collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: Colors.white70, size: 22),
            //     ),
            //   ),
            // ]
          ]),
        ),
      ]),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':     return 'مدير النظام';
      case 'reception': return 'موظف استقبال';
      case 'doctor':    return 'دكتور المعمل';
      default:          return role;
    }
  }
}

class _NavItem {
  final String key; final IconData icon; final String label; final List<String> roles;
  const _NavItem(this.key, this.icon, this.label, this.roles);
}