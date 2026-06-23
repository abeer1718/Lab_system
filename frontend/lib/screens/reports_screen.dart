import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:frontend/services/database_service.dart';
import 'package:sembast/sembast.dart';
import '../services/api_service.dart';
import 'doctor_screen.dart'; 

const _primary = Color(0xFF0277BD);
const _primaryDark = Color(0xFF01579B);
const _bg = Color(0xFFF0F7FF);
const _surface = Colors.white;
const _textPrimary = Color(0xFF263238);
const _textSecondary = Color(0xFF546E7A);
const _textHint = Color(0xFF90A4AE);
const _divider = Color(0xFFE0F0FF);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;

  List<Map<String, dynamic>> _visits = [];
  List<Map<String, dynamic>> _visitTests = [];
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _shiftSessions = [];

  // Date filters
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  // Time range filter (for shift tab)
  TimeOfDay _timeFrom = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _timeTo = const TimeOfDay(hour: 23, minute: 59);
  bool _useTimeFilter = false;

  // Shift sessions filter
  Map<String, dynamic>? _selectedSession;

  // Selected company for the "company claims" tab (null = show grouped list of all companies)
  Map<String, dynamic>? _selectedCompany;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _visits = List<Map<String, dynamic>>.from(await ApiService.getVisits());
    _visitTests =
        List<Map<String, dynamic>>.from(await ApiService.getAllVisitTests());
    _patients = List<Map<String, dynamic>>.from(await ApiService.getPatients());
    _companies =
        List<Map<String, dynamic>>.from(await ApiService.getCompanies());
    _tests = List<Map<String, dynamic>>.from(await ApiService.getTests());
    _shifts = List<Map<String, dynamic>>.from(await ApiService.getShifts());

    // Load all shift sessions
    final db = await DatabaseService.database;
    final store = intMapStoreFactory.store('shift_sessions');
    final records = await store.find(
      db,
      finder: Finder(sortOrders: [SortOrder('start_time', false)]),
    );
    _shiftSessions =
        records.map((r) => {'id': r.key, ...r.value}).toList();

    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filteredVisits => _visits.where((v) {
        final dt = DateTime.tryParse(v['date'] ?? '');
        if (dt == null) return false;
        return dt.isAfter(_from.subtract(const Duration(days: 1))) &&
            dt.isBefore(_to.add(const Duration(days: 1)));
      }).toList();

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _visitInTimeRange(Map<String, dynamic> v) {
    if (!_useTimeFilter) return true;
    final dt = DateTime.tryParse(v['date'] ?? '');
    if (dt == null) return false;
    final vMin = dt.hour * 60 + dt.minute;
    final fromMin = _toMinutes(_timeFrom);
    final toMin = _toMinutes(_timeTo);
    if (fromMin <= toMin) return vMin >= fromMin && vMin <= toMin;
    return vMin >= fromMin || vMin <= toMin;
  }

  List<Map<String, dynamic>> get _timeFilteredVisits =>
      _filteredVisits.where(_visitInTimeRange).toList();

  double get _totalRevenue =>
      _filteredVisits.fold(0, (s, v) => s + (v['total'] as num? ?? 0));
  double get _totalDiscount =>
      _filteredVisits.fold(0, (s, v) => s + (v['discount'] as num? ?? 0));

  // Payment breakdown for filtered visits
  Map<String, double> get _paymentBreakdown {
    final map = <String, double>{
      'cash': 0, 'bank': 0, 'fwry': 0, 'okash': 0, 'mycash': 0,
    };
    for (final v in _filteredVisits) {
      final pm = v['payment_method'] as String? ?? '';
      final amt = (v['total'] as num? ?? 0).toDouble();
      if (map.containsKey(pm)) map[pm] = (map[pm] ?? 0) + amt;
    }
    return map;
  }

  Map<String, int> get _paymentCounts {
    final map = <String, int>{
      'cash': 0, 'bank': 0, 'fwry': 0, 'okash': 0, 'mycash': 0,
    };
    for (final v in _filteredVisits) {
      final pm = v['payment_method'] as String? ?? '';
      if (map.containsKey(pm)) map[pm] = (map[pm] ?? 0) + 1;
    }
    return map;
  }

  // ─── helpers ─────────────────────────────────────────────────────────────────

  Map<String, dynamic>? _patientById(int id) =>
      _patients.where((p) => p['id'] == id).firstOrNull;

  Map<String, dynamic>? _companyById(int? id) =>
      id == null ? null : _companies.where((c) => c['id'] == id).firstOrNull;

  List<Map<String, dynamic>> _visitTestsForVisit(int visitId) =>
      _visitTests.where((vt) => vt['visit_id'] == visitId).toList();

  /// رقم البطاقة بتاع الزيارة - بيجرب بالترتيب: رقم البطاقة بالزيارة، الرقم
  /// القومي بالزيارة، رقم البطاقة بالمريض، الرقم القومي بالمريض، رقم الهوية
  /// بالمريض. (نفس ترتيب البحث القديم)
  String _cardNumberForVisit(Map<String, dynamic> v) {
    final patient = _patientById(v['patient_id'] as int? ?? 0);
    final value = v['card_number'] ??
        v['national_id'] ??
        patient?['card_number'] ??
        patient?['national_id'] ??
        patient?['id_number'];
    return value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : '—';
  }

  String _payLabel(String m) {
    switch (m) {
      case 'cash': return 'كاش';
      case 'bank': return 'بنكك';
      case 'fwry': return 'فوري';
      case 'okash': return 'اوكاش';
      case 'mycash': return 'ماي كاش';
      default: return m.isEmpty ? '—' : m;
    }
  }

  Color _payColor(String m) {
    switch (m) {
      case 'cash': return const Color(0xFF2E7D32);
      case 'bank': return const Color(0xFF0277BD);
      case 'fwry': return const Color(0xFF7B1FA2);
      case 'okash': return const Color(0xFFF57C00);
      case 'mycash': return const Color(0xFF0097A7);
      default: return _textHint;
    }
  }

  IconData _payIcon(String m) {
    switch (m) {
      case 'cash': return Icons.payments_rounded;
      case 'bank': return Icons.account_balance_rounded;
      case 'fwry': return Icons.account_balance_wallet_rounded;
      case 'okash': return Icons.mobile_friendly_rounded;
      case 'mycash': return Icons.phone_iphone_rounded;
      default: return Icons.payment_rounded;
    }
  }

  String _fmtDt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ─── detail sheets ────────────────────────────────────────────────────────────

  void _showVisitDetails(Map<String, dynamic> visit) {
    final patient = _patientById(visit['patient_id'] as int? ?? 0);
    final company = _companyById(visit['company_id'] as int?);
    final tests = _visitTestsForVisit(visit['id'] as int);
    final dt = DateTime.tryParse(visit['date'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VisitDetailSheet(
        visit: visit,
        patient: patient,
        company: company,
        tests: tests,
        dt: dt,
        payLabel: _payLabel,
        payColor: _payColor,
        payIcon: _payIcon,
        fmtDt: _fmtDt,
      ),
    );
  }

void _showGroupDetails({
    required String title,
    required List<Map<String, dynamic>> visits,
    bool canPrint = true,
    VoidCallback? printOverride,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupDetailSheet(
        title: title,
        visits: visits,
        patientById: _patientById,
        companyById: _companyById,
        visitTestsForVisit: _visitTestsForVisit,
        onVisitTap: (v) {
          Navigator.pop(context);
          _showVisitDetails(v);
        },
        payLabel: _payLabel,
        payColor: _payColor,
        payIcon: _payIcon,
        fmtDt: _fmtDt,
        canPrint: canPrint,
        onPrint: canPrint
            ? (printOverride ?? () => _printGroupReport(title: title, visits: visits))
            : null,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // PRINT HELPERS
  // ══════════════════════════════════════════════════════════════════════════════

  /// يبني صف HTML بيعرض الفحوصات اللي تمت في الزيارة (اسم الفحص + سعره) - يستخدم
  /// في تقارير الوقت والمرضى عشان توضح "الفحوصات اللي سواها" المريض، مش فقط الإجمالي.
  String _testsHtmlForVisit(Map<String, dynamic> v) {
    final tests = _visitTestsForVisit(v['id'] as int);
    if (tests.isEmpty) return '—';
    return tests.map((t) {
      final name = t['test_name'] as String? ?? 'فحص';
      final price = (t['price_at_time'] as num? ?? 0).toStringAsFixed(0);
      return '$name ($price ج)';
    }).join('، ');
  }

void _printGroupReport({
    required String title,
    required List<Map<String, dynamic>> visits,
    String? subtitle,
  }) {
    double totalRevenue =
        visits.fold(0, (s, v) => s + (v['total'] as num? ?? 0));
    double totalDiscount =
        visits.fold(0, (s, v) => s + (v['discount'] as num? ?? 0));

    final pmTotals = <String, double>{};
    final pmCounts = <String, int>{};
    for (final v in visits) {
      final pm = v['payment_method'] as String? ?? 'cash';
      final amt = (v['total'] as num? ?? 0).toDouble();
      pmTotals[pm] = (pmTotals[pm] ?? 0) + amt;
      pmCounts[pm] = (pmCounts[pm] ?? 0) + 1;
    }

    String payBlock(String method) {
      final count = pmCounts[method] ?? 0;
      if (count == 0) return '';
      final total = pmTotals[method] ?? 0;
      final label = _payLabel(method);
      final color = _payColorHex(method);
      return '''
        <div class="pay-row" style="border-right:4px solid $color">
          <span class="pay-label">$label</span>
          <span class="pay-count">$count زيارة</span>
          <span class="pay-total" style="color:$color">${total.toStringAsFixed(0)} ج</span>
        </div>''';
    }

    // ── ملاحظة: تمت إضافة عمود "الفحوصات" عشان التقرير يوضح بالتفصيل
    // اسم كل مريض + الفحوصات اللي سواها، مش بس الإجمالي.
    final rows = visits.map((v) {
      final dt = DateTime.tryParse(v['date'] ?? '') ?? DateTime.now();
      final patient = _patientById(v['patient_id'] as int? ?? 0);
      final pm = _payLabel(v['payment_method'] ?? '');
      final pmColor = _payColorHex(v['payment_method'] ?? '');
      final testsHtml = _testsHtmlForVisit(v);
      return '''<tr>
        <td>${patient?['name'] ?? v['patient_name'] ?? '—'}</td>
        <td>${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}</td>
        <td style="font-size:11px">$testsHtml</td>
        <td style="color:$pmColor;font-weight:700">$pm</td>
        <td style="font-weight:800;color:#0277BD">${(v['total'] as num? ?? 0).toStringAsFixed(0)} ج</td>
        ${(v['discount'] as num? ?? 0) > 0 ? '<td style="color:#F59E0B">${(v['discount'] as num).toStringAsFixed(0)} ج</td>' : '<td>—</td>'}
      </tr>''';
    }).join('\n');

    final htmlContent = '''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>$title</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap');
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Cairo',sans-serif;background:#fff;color:#263238;padding:28px;direction:rtl}
${_printHeaderCss()}
.summary{display:flex;background:linear-gradient(135deg,#0277BD,#01579B);border-radius:12px;padding:16px;margin-bottom:18px;color:#fff;gap:0}
.sum-col{flex:1;text-align:center}
.sum-col .val{font-size:20px;font-weight:800}
.sum-col .lbl{font-size:11px;opacity:.8;margin-top:2px}
.divider{width:1px;background:rgba(255,255,255,.2);margin:0 8px}
.section-title{font-size:13px;font-weight:800;color:#263238;margin:16px 0 8px}
.pay-row{display:flex;align-items:center;gap:12px;background:#f9f9f9;border-radius:8px;padding:10px 14px;margin-bottom:7px}
.pay-label{font-weight:700;flex:1}
.pay-count{font-size:11px;color:#90A4AE}
.pay-total{font-weight:800;font-size:15px;min-width:80px;text-align:left}
table{width:100%;border-collapse:collapse;margin-top:8px}
thead tr{background:#0277BD;color:#fff}
thead th{padding:10px 14px;font-size:12px;text-align:right}
tbody tr:nth-child(even){background:#F0F7FF}
tbody td{padding:9px 14px;font-size:12px;border-bottom:1px solid #E0F0FF;vertical-align:top;line-height:1.6}
.footer{margin-top:20px;padding-top:14px;border-top:1px solid #E0F0FF;text-align:center;font-size:11px;color:#90A4AE}
@media print{body{padding:12px}}
</style>
</head>
<body>
${_printHeaderHtml(title: title, subtitle: subtitle)}
<div class="summary">
  <div class="sum-col"><div class="val">${visits.length}</div><div class="lbl">إجمالي الزيارات</div></div>
  <div class="divider"></div>
  <div class="sum-col"><div class="val">${totalRevenue.toStringAsFixed(0)} ج</div><div class="lbl">إجمالي الإيرادات</div></div>
  ${totalDiscount > 0 ? '<div class="divider"></div><div class="sum-col"><div class="val">${totalDiscount.toStringAsFixed(0)} ج</div><div class="lbl">إجمالي الخصومات</div></div>' : ''}
</div>
<div class="section-title">تفصيل طرق الدفع</div>
${payBlock('cash')}${payBlock('bank')}${payBlock('fwry')}${payBlock('okash')}${payBlock('mycash')}
<div class="section-title">تفصيل الزيارات</div>
<table>
  <thead><tr><th>المريض</th><th>التاريخ والوقت</th><th>الفحوصات</th><th>طريقة الدفع</th><th>المبلغ</th><th>الخصم</th></tr></thead>
  <tbody>$rows</tbody>
</table>
<div class="footer">مختبر الفادي — نظام إدارة المعمل © ${DateTime.now().year}</div>
<script>window.onload=function(){window.print()}</script>
</body></html>''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

void _printSummaryReport() {
    final breakdown = _paymentBreakdown;
    final counts = _paymentCounts;

    String payBlock(String method) {
      final count = counts[method] ?? 0;
      if (count == 0) return '';
      final total = breakdown[method] ?? 0;
      final label = _payLabel(method);
      final color = _payColorHex(method);
      return '''
        <div class="pay-row" style="border-right:4px solid $color">
          <span class="pay-label">$label</span>
          <span class="pay-count">$count زيارة</span>
          <span class="pay-total" style="color:$color">${total.toStringAsFixed(0)} ج</span>
        </div>''';
    }

    final htmlContent = '''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>تقرير ملخص - مختبر الفادي</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap');
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Cairo',sans-serif;background:#fff;color:#263238;padding:28px;direction:rtl}
${_printHeaderCss()}
.summary{display:flex;background:linear-gradient(135deg,#0277BD,#01579B);border-radius:12px;padding:20px;margin-bottom:18px;color:#fff;gap:0}
.sum-col{flex:1;text-align:center}
.sum-col .val{font-size:22px;font-weight:800}
.sum-col .lbl{font-size:11px;opacity:.8;margin-top:3px}
.divider{width:1px;background:rgba(255,255,255,.2);margin:0 8px}
.section-title{font-size:14px;font-weight:800;color:#263238;margin:16px 0 8px}
.pay-row{display:flex;align-items:center;gap:12px;background:#f9f9f9;border-radius:8px;padding:12px 16px;margin-bottom:8px}
.pay-label{font-weight:700;flex:1;font-size:14px}
.pay-count{font-size:12px;color:#90A4AE}
.pay-total{font-weight:800;font-size:16px;min-width:90px;text-align:left}
.meta{display:flex;gap:20px;background:#F0F7FF;border-radius:10px;padding:12px 16px;margin-bottom:18px}
.meta-item label{font-size:10px;color:#90A4AE;display:block}
.meta-item span{font-size:13px;font-weight:700}
.footer{margin-top:24px;padding-top:14px;border-top:1px solid #E0F0FF;text-align:center;font-size:11px;color:#90A4AE}
@media print{body{padding:12px}}
</style>
</head>
<body>
${_printHeaderHtml(title: 'تقرير ملخص النشاط')}
<div class="meta">
  <div class="meta-item"><label>من تاريخ</label><span>${_from.day}/${_from.month}/${_from.year}</span></div>
  <div class="meta-item"><label>إلى تاريخ</label><span>${_to.day}/${_to.month}/${_to.year}</span></div>
  <div class="meta-item"><label>إجمالي المرضى</label><span>${_patients.length}</span></div>
</div>
<div class="summary">
  <div class="sum-col"><div class="val">${_filteredVisits.length}</div><div class="lbl">إجمالي الزيارات</div></div>
  <div class="divider"></div>
  <div class="sum-col"><div class="val">${_totalRevenue.toStringAsFixed(0)} ج</div><div class="lbl">إجمالي الإيرادات</div></div>
  <div class="divider"></div>
  <div class="sum-col"><div class="val">${_totalDiscount.toStringAsFixed(0)} ج</div><div class="lbl">إجمالي الخصومات</div></div>
</div>
<div class="section-title">تفصيل طرق الدفع</div>
${payBlock('cash')}${payBlock('bank')}${payBlock('fwry')}${payBlock('okash')}${payBlock('mycash')}
<div class="footer">مختبر الفادي — نظام إدارة المعمل © ${DateTime.now().year}</div>
<script>window.onload=function(){window.print()}</script>
</body></html>''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  String _payColorHex(String m) {
    switch (m) {
      case 'cash': return '#2E7D32';
      case 'bank': return '#0277BD';
      case 'fwry': return '#7B1FA2';
      case 'okash': return '#F57C00';
      case 'mycash': return '#0097A7';
      default: return '#546E7A';
    }
  }

// ─── هيدر موحّد لكل التقارير (نفس شعار نتائج التحاليل) ──────────────────────

  String _printHeaderCss() => '''
    .header-logo{text-align:center;margin-bottom:6px}
    .header-logo img{max-width:100%;height:auto;max-height:100px;object-fit:contain}
    .sub-line{text-align:center;font-size:12px;color:#546E7A;margin-top:2px;margin-bottom:10px;font-weight:700}
    hr.thick{border:none;border-top:3px solid #8B0000;margin:10px 0 16px}
    .report-meta{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:16px}
    .report-title{font-size:16px;font-weight:800;color:#263238}
    .report-sub{font-size:12px;color:#546E7A;margin-top:3px}
    .report-date{font-size:11px;color:#90A4AE;margin-top:4px}
  ''';

  String _printHeaderHtml({required String title, String? subtitle}) => '''
    <div class="header-logo"><img src="$kHeaderLogoBase64" alt="Elfadi Specialized Hospital"></div>
    <div class="sub-line">قسم المعمل</div>
    <hr class="thick">
    <div class="report-meta">
      <div>
        <div class="report-title">$title</div>
        ${subtitle != null ? '<div class="report-sub">$subtitle</div>' : ''}
      </div>
      <div class="report-date">طُبع: ${_fmtDt(DateTime.now())}</div>
    </div>
  ''';

  // ─── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: [
        _header(),
        if (_loading)
          const Expanded(
              child: Center(
                  child: CircularProgressIndicator(color: _primary)))
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                _dateFilter(),
                const SizedBox(height: 16),
                _summaryCards(),
                const SizedBox(height: 12),
                _paymentBreakdownRow(),
                const SizedBox(height: 20),
                _tabsContainer(),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: const BoxDecoration(
          color: _surface,
          border: Border(bottom: BorderSide(color: _divider, width: 2)),
          boxShadow: [
            BoxShadow(
                color: Color(0x0F0277BD),
                blurRadius: 12,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('التقارير',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryDark,
                    fontFamily: 'Cairo')),
            Text('تقارير شاملة عن نشاط المعمل',
                style: TextStyle(
                    fontSize: 12, color: _textHint, fontFamily: 'Cairo')),
          ]),
          const Spacer(),
          // Print summary button
          OutlinedButton.icon(
            onPressed: _printSummaryReport,
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('طباعة الملخص',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ]),
      );

  // ─── date filter ──────────────────────────────────────────────────────────────

  Widget _dateFilter() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(children: [
          const Icon(Icons.date_range_rounded, color: _primary, size: 20),
          const SizedBox(width: 10),
          const Text('الفترة:',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                  color: _textPrimary)),
          const SizedBox(width: 16),
          _datePicker('من', _from, (d) => setState(() => _from = d)),
          const SizedBox(width: 12),
          _datePicker('إلى', _to, (d) => setState(() => _to = d)),
          const Spacer(),
          ...['اليوم', 'أسبوع', 'شهر'].map((l) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _to = now;
                      if (l == 'اليوم')
                        _from = DateTime(now.year, now.month, now.day);
                      else if (l == 'أسبوع')
                        _from = now.subtract(const Duration(days: 7));
                      else
                        _from = now.subtract(const Duration(days: 30));
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  child: Text(l,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              )),
        ]),
      );

  Widget _datePicker(
          String label, DateTime dt, ValueChanged<DateTime> onPick) =>
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
              context: context,
              initialDate: dt,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030));
          if (picked != null) onPick(picked);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _divider),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: _primary),
            const SizedBox(width: 6),
            Text('$label: ${dt.day}/${dt.month}/${dt.year}',
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ]),
        ),
      );

  // ─── summary cards ────────────────────────────────────────────────────────────

  Widget _summaryCards() {
    final cards = [
      ('إجمالي الزيارات', '${_filteredVisits.length}',
          Icons.local_hospital_rounded, const Color(0xFF0277BD)),
      ('الإيرادات', '${_totalRevenue.toStringAsFixed(0)} ج',
          Icons.payments_rounded, const Color(0xFF2E7D32)),
      ('الخصومات', '${_totalDiscount.toStringAsFixed(0)} ج',
          Icons.discount_rounded, const Color(0xFFF59E0B)),
      ('المرضى', '${_patients.length}', Icons.people_rounded,
          const Color(0xFF8B5CF6)),
    ];
    return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 10,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c.$4.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(c.$3, color: c.$4, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.$1,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _textHint,
                                        fontFamily: 'Cairo')),
                                Text(c.$2,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: c.$4,
                                        fontFamily: 'Cairo')),
                              ]),
                        ),
                      ]),
                    ),
                  ),
                ))
            .toList());
  }

  // ─── payment breakdown row ────────────────────────────────────────────────────

  Widget _paymentBreakdownRow() {
    final breakdown = _paymentBreakdown;
    final counts = _paymentCounts;
    final methods = ['cash', 'bank', 'fwry', 'okash', 'mycash'];
    final active = methods.where((m) => (counts[m] ?? 0) > 0).toList();

    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: _primary, size: 18),
          const SizedBox(width: 8),
          const Text('تفصيل طرق الدفع',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _textPrimary)),
        ]),
        const SizedBox(height: 12),
        Row(
          children: active.map((m) {
            final color = _payColor(m);
            final total = breakdown[m] ?? 0;
            final count = counts[m] ?? 0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(_payIcon(m), color: color, size: 16),
                          const SizedBox(width: 6),
                          Text(_payLabel(m),
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: color)),
                        ]),
                        const SizedBox(height: 6),
                        Text('${total.toStringAsFixed(0)} ج',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: color)),
                        Text('$count زيارة',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: _textHint)),
                      ]),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ─── tabs container ───────────────────────────────────────────────────────────

  Widget _tabsContainer() => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 2))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF0F7FF),
              border: Border(bottom: BorderSide(color: _divider)),
            ),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              labelStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
              unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w500,
                  fontSize: 13),
              labelColor: _primary,
              unselectedLabelColor: _textSecondary,
              indicatorColor: _primary,
              indicatorWeight: 3,
              onTap: (_) {
                // الرجوع للقائمة العامة للشركات لما نطلع من تبويب الشركة ونرجع له تاني
                setState(() => _selectedCompany = null);
              },
              tabs: const [
                Tab(text: 'حسب الوقت'),
                Tab(text: 'حسب الفحص'),
                Tab(text: 'حسب المريض'),
                Tab(text: 'حسب الشركة'),
                Tab(text: 'تقارير الورديات'),
              ],
            ),
          ),
          SizedBox(
            height: 560,
            child: TabBarView(
              controller: _tabs,
              children: [
                _timeRangeReport(),
                _testReport(),
                _patientReport(),
                _companyReport(),
                _shiftSessionsReport(),
              ],
            ),
          ),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 1 — Time Range Report
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _timeRangeReport() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _divider),
          ),
          child: Row(children: [
            const Icon(Icons.access_time_rounded, color: _primary, size: 18),
            const SizedBox(width: 8),
            const Text('فلتر الوقت:',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _textPrimary)),
            const SizedBox(width: 12),
            _timePicker('من', _timeFrom, (t) {
              setState(() {
                _timeFrom = t;
                _useTimeFilter = true;
              });
            }),
            const SizedBox(width: 8),
            _timePicker('إلى', _timeTo, (t) {
              setState(() {
                _timeTo = t;
                _useTimeFilter = true;
              });
            }),
            const SizedBox(width: 8),
            if (_useTimeFilter)
              TextButton.icon(
                onPressed: () => setState(() => _useTimeFilter = false),
                icon: const Icon(Icons.clear, size: 14),
                label: const Text('إلغاء',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400),
              ),
            const Spacer(),
            // Print button for time report
            OutlinedButton.icon(
              onPressed: () => _printGroupReport(
                title: 'تقرير الزيارات - حسب الوقت',
                subtitle: 'من ${_from.day}/${_from.month}/${_from.year} إلى ${_to.day}/${_to.month}/${_to.year}',
                visits: _timeFilteredVisits,
              ),
              icon: const Icon(Icons.print_rounded, size: 15),
              label: const Text('طباعة',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _divider),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Builder(builder: (_) {
          final visits = _timeFilteredVisits;
          final Map<String, List<Map<String, dynamic>>> byDate = {};
          for (final v in visits) {
            final dt =
                DateTime.tryParse(v['date'] ?? '') ?? DateTime.now();
            final key =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            byDate.putIfAbsent(key, () => []).add(v);
          }
          final sorted = byDate.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key));

          if (sorted.isEmpty) return _emptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final entry = sorted[i];
              final total = entry.value
                  .fold(0.0, (s, v) => s + (v['total'] as num? ?? 0));

              // عدد الفحوصات المختلفة المنفذة في هذا اليوم - لمحة سريعة على الكارت
              final testNamesForDay = <String>{};
              for (final v in entry.value) {
                for (final t in _visitTestsForVisit(v['id'] as int)) {
                  testNamesForDay.add(t['test_name'] as String? ?? '');
                }
              }
              testNamesForDay.removeWhere((e) => e.isEmpty);

              return InkWell(
                onTap: () => _showGroupDetails(
                  title: 'زيارات يوم ${entry.key}',
                  visits: entry.value,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _divider),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.today_rounded,
                            color: _primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                      color: _textPrimary)),
                              Text(
                                  '${entry.value.length} زيارة${_useTimeFilter ? ' (في النطاق الزمني)' : ''}  •  ${testNamesForDay.length} نوع فحص',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _textHint,
                                      fontFamily: 'Cairo')),
                            ]),
                      ),
                      Row(children: [
                        Text('${total.toStringAsFixed(0)} ج',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _primary,
                                fontFamily: 'Cairo')),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_left_rounded,
                            color: _textHint, size: 20),
                      ]),
                    ]),
                    // أسماء المرضى اللي زاروا في هذا اليوم - لمحة سريعة
                    if (entry.value.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.value.take(6).map((v) {
                          final p = _patientById(v['patient_id'] as int? ?? 0);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _divider),
                            ),
                            child: Text(
                              p?['name'] ?? v['patient_name'] ?? '—',
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary),
                            ),
                          );
                        }).toList()
                          ..addAll(entry.value.length > 6
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+${entry.value.length - 6} آخرين',
                                      style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _primary),
                                    ),
                                  )
                                ]
                              : []),
                      ),
                    ],
                  ]),
                ),
              );
            },
          );
        }),
      ),
    ]);
  }

  Widget _timePicker(
          String label, TimeOfDay t, ValueChanged<TimeOfDay> onPick) =>
      InkWell(
        onTap: () async {
          final picked =
              await showTimePicker(context: context, initialTime: t);
          if (picked != null) onPick(picked);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _divider),
          ),
          child: Row(children: [
            const Icon(Icons.schedule_rounded, size: 14, color: _primary),
            const SizedBox(width: 5),
            Text(
                '$label: ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ]),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 2 — Test Report
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _testReport() {
    final filteredVisitIds =
        _filteredVisits.map((v) => v['id'] as int).toSet();
    final filteredVT = _visitTests
        .where((vt) => filteredVisitIds.contains(vt['visit_id'] as int?))
        .toList();

    final Map<String, List<Map<String, dynamic>>> byTest = {};
    for (final vt in filteredVT) {
      final name = vt['test_name'] as String? ?? 'غير معروف';
      byTest.putIfAbsent(name, () => []).add(vt);
    }
    final sorted = byTest.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (sorted.isEmpty) return _emptyState();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton.icon(
            onPressed: () => _printGroupReport(
              title: 'تقرير الفحوصات',
              subtitle: 'من ${_from.day}/${_from.month}/${_from.year} إلى ${_to.day}/${_to.month}/${_to.year}',
              visits: _filteredVisits,
            ),
            icon: const Icon(Icons.print_rounded, size: 15),
            label: const Text('طباعة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final e = sorted[i];
            final revenue = e.value.fold(
                0.0, (s, vt) => s + (vt['price_at_time'] as num? ?? 0));
            final visitIds =
                e.value.map((vt) => vt['visit_id'] as int).toSet();
            final visitsForTest = _filteredVisits
                .where((v) => visitIds.contains(v['id'] as int))
                .toList();

            return InkWell(
              onTap: () => _showGroupDetails(
                title: 'فحص: ${e.key}',
                visits: visitsForTest,
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _divider),
                ),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.science_outlined,
                        color: _primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(e.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                              color: _textPrimary))),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${e.value.length} مرة',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                color: _primary,
                                fontSize: 13)),
                        Text('${revenue.toStringAsFixed(0)} ج',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: _textHint)),
                      ]),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_left_rounded,
                      color: _textHint, size: 20),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 3 — Patient Report
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _patientReport() {
    final Map<int, List<Map<String, dynamic>>> byPatient = {};
    for (final v in _filteredVisits) {
      final pid = v['patient_id'] as int? ?? 0;
      byPatient.putIfAbsent(pid, () => []).add(v);
    }
    final sorted = byPatient.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (sorted.isEmpty) return _emptyState();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton.icon(
            onPressed: () => _printGroupReport(
              title: 'تقرير المرضى',
              subtitle: 'من ${_from.day}/${_from.month}/${_from.year} إلى ${_to.day}/${_to.month}/${_to.year}',
              visits: _filteredVisits,
            ),
            icon: const Icon(Icons.print_rounded, size: 15),
            label: const Text('طباعة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final e = sorted[i];
            final p = _patientById(e.key);
            final total =
                e.value.fold(0.0, (s, v) => s + (v['total'] as num? ?? 0));

            // كل الفحوصات اللي سواها هذا المريض خلال الفترة - تُعرض كملخص على الكارت
            final testNames = <String>[];
            for (final v in e.value) {
              for (final t in _visitTestsForVisit(v['id'] as int)) {
                final n = t['test_name'] as String?;
                if (n != null && n.isNotEmpty) testNames.add(n);
              }
            }

            return InkWell(
              onTap: () => _showGroupDetails(
                title: 'مريض: ${p?['name'] ?? '—'}',
                visits: e.value,
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _divider),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: Text(
                        (p?['name'] as String? ?? '?')[0],
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            color: _primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p?['name'] ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                    color: _textPrimary)),
                            Text(p?['phone'] ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _textHint,
                                    fontFamily: 'Cairo')),
                          ]),
                    ),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${e.value.length} زيارة',
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                  fontSize: 13)),
                          Text('${total.toStringAsFixed(0)} ج',
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: _textHint)),
                        ]),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_left_rounded,
                        color: _textHint, size: 20),
                  ]),
                  // الفحوصات اللي سواها المريض - عرض سريع تحت الكارت
                  if (testNames.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: testNames.toSet().map((n) {
                        final count = testNames.where((x) => x == n).length;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            count > 1 ? '$n ×$count' : n,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 4 — Company Report
  // ══════════════════════════════════════════════════════════════════════════════
  //
  // - الوضع الافتراضي: قائمة كل الشركات (طباعة عامة لكل شركة على حدة).
  // - عند اختيار/الضغط على شركة: تظهر تفاصيل المرضى التابعين لها مباشرة في
  //   الشاشة (اسم المريض، رقم البطاقة، الفحوصات، السعر، الخصم) + إجمالي
  //   المطالبة في الأسفل، مع زر رجوع للقائمة وزر طباعة مطالبة الشركة.
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _companyReport() {
    if (_selectedCompany != null) {
      return _companyClaimDetail(_selectedCompany!);
    }
    return _companyListView();
  }

  Widget _companyListView() {
    final Map<int?, List<Map<String, dynamic>>> byCompany = {};
    for (final v in _filteredVisits) {
      final cid = v['company_id'] as int?;
      byCompany.putIfAbsent(cid, () => []).add(v);
    }
    final sorted = byCompany.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (sorted.isEmpty) return _emptyState();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton.icon(
            onPressed: () => _printGroupReport(
              title: 'تقرير الشركات',
              subtitle: 'من ${_from.day}/${_from.month}/${_from.year} إلى ${_to.day}/${_to.month}/${_to.year}',
              visits: _filteredVisits,
            ),
            icon: const Icon(Icons.print_rounded, size: 15),
            label: const Text('طباعة عامة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final e = sorted[i];
            final c = _companyById(e.key);
            final total =
                e.value.fold(0.0, (s, v) => s + (v['total'] as num? ?? 0));
            final discount =
                e.value.fold(0.0, (s, v) => s + (v['discount'] as num? ?? 0));

            return InkWell(
              onTap: () {
                if (c != null) {
                  // اختيار شركة معيّنة -> يظهر تفصيل المرضى والمطالبة في الشاشة
                  setState(() => _selectedCompany = c);
                } else {
                  // زيارات عامة بدون شركة - مفيش مطالبة هنا، تفصيل عادي بس
                  _showGroupDetails(
                    title: 'عام (بدون شركة)',
                    visits: e.value,
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _divider),
                ),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business_rounded,
                        color: Color(0xFF2E7D32), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c?['name'] ?? 'عام (بدون شركة)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Cairo',
                                  color: _textPrimary)),
                          if (discount > 0)
                            Text('مطالبة: ${discount.toStringAsFixed(0)} ج',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo')),
                        ]),
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${e.value.length} زيارة',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                color: _primary,
                                fontSize: 13)),
                        Text('${total.toStringAsFixed(0)} ج',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: _textHint)),
                      ]),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_left_rounded,
                      color: _textHint, size: 20),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  /// شاشة تفصيل المطالبة الخاصة بشركة معيّنة: تعرض كل مريض تابع للشركة مع
  /// رقم بطاقته، الفحوصات اللي سواها وسعر كل فحص، قيمة الخصم على زيارته،
  /// والإجمالي. في الأسفل إجمالي المطالبة الكلي المطلوب من الشركة.
  Widget _companyClaimDetail(Map<String, dynamic> company) {
    final visits = _filteredVisits
        .where((v) => v['company_id'] == company['id'])
        .toList()
      ..sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));

    // حساب أكثر أماناً
    final totalClaim = visits.fold<double>(0.0, (s, v) {
      final discount = v['discount'];
      if (discount == null) return s;
      return s + (discount is num ? discount.toDouble() : double.tryParse(discount.toString()) ?? 0.0);
    });

    final totalRevenue = visits.fold<double>(0.0, (s, v) {
      final total = v['total'];
      if (total == null) return s;
      return s + (total is num ? total.toDouble() : double.tryParse(total.toString()) ?? 0.0);
    });

    final discountPercent = company['discount_percent'];

    return Column(children: [
      // شريط علوي: رجوع + اسم الشركة + زر طباعة المطالبة
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _divider),
          ),
          child: Row(children: [
            InkWell(
              onTap: () => setState(() => _selectedCompany = null),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _divider),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: _primary),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_rounded,
                  color: Color(0xFF2E7D32), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company['name'] ?? '—',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: _textPrimary)),
                    if (discountPercent != null)
                      Text('نسبة الخصم: $discountPercent%',
                          style: const TextStyle(
                              fontSize: 11,
                              color: _textHint,
                              fontFamily: 'Cairo')),
                  ]),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  _printCompanyClaimReport(company: company, visits: visits),
              icon: const Icon(Icons.print_rounded, size: 16),
              label: const Text('طباعة المطالبة',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      // ملخص علوي: عدد الزيارات / الإيراد / إجمالي المطالبة
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: _claimSummaryChip('عدد الزيارات', '${visits.length}', _primary, Icons.receipt_long_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _claimSummaryChip('إجمالي القيمة', '${totalRevenue.toStringAsFixed(0)} ج', const Color(0xFF2E7D32), Icons.payments_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _claimSummaryChip('إجمالي المطالبة', '${totalClaim.toStringAsFixed(0)} ج', const Color(0xFFF59E0B), Icons.request_quote_rounded)),
        ]),
      ),
      const SizedBox(height: 10),
      // جدول تفصيلي...
      Expanded(
        child: visits.isEmpty
            ? _emptyState(message: 'لا توجد زيارات لهذه الشركة خلال الفترة المحددة')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final v = visits[i];
                  final patient = _patientById(v['patient_id'] as int? ?? 0);
                  final tests = _visitTestsForVisit(v['id'] as int);
                  final dt = DateTime.tryParse(v['date'] ?? '');
                  final cardNumber = _cardNumberForVisit(v);
                  final rowTotal = tests.fold<double>(
                      0, (s, t) => s + (t['price_at_time'] as num? ?? 0).toDouble());
                  final discount = (v['discount'] as num? ?? 0).toDouble();

                  return InkWell(
                    onTap: () => _showVisitDetails(v),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _divider),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFE3F2FD),
                            child: Text(
                              (patient?['name'] as String? ?? '?')[0],
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: _primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(patient?['name'] ?? v['patient_name'] ?? '—',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Cairo',
                                          fontSize: 13,
                                          color: _textPrimary)),
                                  Row(children: [
                                    const Icon(Icons.badge_outlined,
                                        size: 12, color: _textHint),
                                    const SizedBox(width: 3),
                                    Text('رقم البطاقة: $cardNumber',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: _textHint,
                                            fontFamily: 'Cairo')),
                                    if (dt != null) ...[
                                      const SizedBox(width: 10),
                                      Text(
                                          '${dt.day}/${dt.month}/${dt.year}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: _textHint,
                                              fontFamily: 'Cairo')),
                                    ],
                                  ]),
                                ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${rowTotal.toStringAsFixed(0)} ج',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _primary,
                                    fontFamily: 'Cairo')),
                            if (discount > 0)
                              Text('مطالبة: ${discount.toStringAsFixed(0)} ج',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFF59E0B),
                                      fontFamily: 'Cairo')),
                          ]),
                        ]),
                        if (tests.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: tests.map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _bg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _divider),
                                ),
                                child: Text(
                                  '${t['test_name'] ?? 'فحص'} — ${(t['price_at_time'] as num? ?? 0).toStringAsFixed(0)} ج',
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _textSecondary),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
  Widget _claimSummaryChip(String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: color),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: color)),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 5 — Shift Sessions Report
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _shiftSessionsReport() {
    if (_shiftSessions.isEmpty) {
      return _emptyState(
        icon: Icons.alarm_off_rounded,
        message: 'لا توجد ورديات مسجلة',
      );
    }

    return Column(children: [
      // Header info
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _divider),
          ),
          child: Row(children: [
            const Icon(Icons.history_rounded, color: _primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'إجمالي الورديات المسجلة: ${_shiftSessions.length}',
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _textPrimary),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      // Sessions list
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: _shiftSessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final session = _shiftSessions[i];
            return _shiftSessionCard(session);
          },
        ),
      ),
    ]);
  }

  Widget _shiftSessionCard(Map<String, dynamic> session) {
    final startDt = DateTime.tryParse(session['start_time'] ?? '');
    final endDt = session['end_time'] != null
        ? DateTime.tryParse(session['end_time'])
        : null;
    final isOpen = session['status'] == 'open';
    final shiftName = session['shift_name'] as String? ?? 'وردية';
    final userName = session['user_name'] as String? ?? '—';

    // Find visits for this session
    final sessionVisits = _visits
        .where((v) => v['session_id'] == session['id'])
        .toList();

    final totalRevenue =
        sessionVisits.fold(0.0, (s, v) => s + (v['total'] as num? ?? 0));

    // Payment breakdown for session
    final pmTotals = <String, double>{};
    final pmCounts = <String, int>{};
    for (final v in sessionVisits) {
      final pm = v['payment_method'] as String? ?? 'cash';
      final amt = (v['total'] as num? ?? 0).toDouble();
      pmTotals[pm] = (pmTotals[pm] ?? 0) + amt;
      pmCounts[pm] = (pmCounts[pm] ?? 0) + 1;
    }
    final activeMethods =
        pmTotals.keys.where((k) => (pmCounts[k] ?? 0) > 0).toList();

    return InkWell(
      onTap: () => _showSessionDetail(session, sessionVisits),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isOpen
                  ? const Color(0xFF4CAF50).withOpacity(0.4)
                  : _divider,
              width: isOpen ? 2 : 1),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isOpen
                    ? const Color(0xFF4CAF50).withOpacity(0.12)
                    : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isOpen ? Icons.play_circle_rounded : Icons.stop_circle_rounded,
                color: isOpen ? const Color(0xFF4CAF50) : _primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(shiftName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              color: _textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFF4CAF50).withOpacity(0.1)
                              : const Color(0xFF0277BD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOpen ? 'مفتوحة' : 'مغلقة',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOpen
                                  ? const Color(0xFF4CAF50)
                                  : _primary),
                        ),
                      ),
                    ]),
                    Row(children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: _textHint),
                      const SizedBox(width: 4),
                      Text(userName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: _textHint,
                              fontFamily: 'Cairo')),
                    ]),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${totalRevenue.toStringAsFixed(0)} ج',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: _primary,
                      fontFamily: 'Cairo')),
              Text('${sessionVisits.length} زيارة',
                  style: const TextStyle(
                      fontSize: 12,
                      color: _textHint,
                      fontFamily: 'Cairo')),
            ]),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_left_rounded,
                color: _textHint, size: 20),
          ]),
          const SizedBox(height: 10),
          // Times row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.login_rounded,
                  size: 14, color: Color(0xFF2E7D32)),
              const SizedBox(width: 4),
              Text(
                startDt != null ? _fmtDt(startDt) : '—',
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: _textPrimary,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              if (endDt != null) ...[
                const Icon(Icons.logout_rounded,
                    size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text(
                  _fmtDt(endDt),
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: _textPrimary,
                      fontWeight: FontWeight.w600),
                ),
              ] else
                const Text('لم تُغلق بعد',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w700)),
            ]),
          ),
          // Payment mini breakdown
          if (activeMethods.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ...activeMethods.map((m) {
                final color = _payColor(m);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_payIcon(m), color: color, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${_payLabel(m)}: ${(pmTotals[m] ?? 0).toStringAsFixed(0)} ج',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ]),
                );
              }),
            ]),
          ],
        ]),
      ),
    );
  }

  void _showSessionDetail(
      Map<String, dynamic> session, List<Map<String, dynamic>> visits) {
    final shiftName = session['shift_name'] as String? ?? 'وردية';
    final userName = session['user_name'] as String? ?? '—';
    final startDt = DateTime.tryParse(session['start_time'] ?? '');
    final endDt = session['end_time'] != null
        ? DateTime.tryParse(session['end_time'])
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionDetailSheet(
        session: session,
        visits: visits,
        shiftName: shiftName,
        userName: userName,
        startDt: startDt,
        endDt: endDt,
        patientById: _patientById,
        companyById: _companyById,
        visitTestsForVisit: _visitTestsForVisit,
        payLabel: _payLabel,
        payColor: _payColor,
        payIcon: _payIcon,
        fmtDt: _fmtDt,
        onVisitTap: (v) {
          Navigator.pop(context);
          _showVisitDetails(v);
        },
        onPrint: () => _printSessionReport(
          session: session,
          visits: visits,
          shiftName: shiftName,
          userName: userName,
          startDt: startDt ?? DateTime.now(),
          endDt: endDt ?? DateTime.now(),
        ),
      ),
    );
  }

void _printSessionReport({
    required Map<String, dynamic> session,
    required List<Map<String, dynamic>> visits,
    required String shiftName,
    required String userName,
    required DateTime startDt,
    required DateTime endDt,
  }) {
    double totalCash = 0, totalBank = 0, totalFwry = 0,
        totalOkash = 0, totalMycash = 0, grandTotal = 0;
    int countCash = 0, countBank = 0, countFwry = 0,
        countOkash = 0, countMycash = 0;

    for (final v in visits) {
      final amount = (v['total'] as num? ?? 0).toDouble();
      grandTotal += amount;
      switch (v['payment_method'] as String? ?? '') {
        case 'cash': totalCash += amount; countCash++; break;
        case 'bank': totalBank += amount; countBank++; break;
        case 'fwry': totalFwry += amount; countFwry++; break;
        case 'okash': totalOkash += amount; countOkash++; break;
        case 'mycash': totalMycash += amount; countMycash++; break;
      }
    }

    String payBlock(String label, int count, double total, String color) {
      if (count == 0) return '';
      return '''
        <div class="pay-row" style="border-right:4px solid $color">
          <span class="pay-label">$label</span>
          <span class="pay-count">$count زيارة</span>
          <span class="pay-total" style="color:$color">${total.toStringAsFixed(0)} ج</span>
        </div>''';
    }

    final rows = visits.map((v) {
      final dt = DateTime.tryParse(v['date'] ?? '') ?? DateTime.now();
      final patient = _patientById(v['patient_id'] as int? ?? 0);
      final pm = _payLabel(v['payment_method'] ?? '');
      final pmColor = _payColorHex(v['payment_method'] ?? '');
      return '''<tr>
        <td>${patient?['name'] ?? v['patient_name'] ?? '—'}</td>
        <td>${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}</td>
        <td style="color:$pmColor;font-weight:700">$pm</td>
        <td style="font-weight:800;color:#0277BD">${(v['total'] as num? ?? 0).toStringAsFixed(0)} ج</td>
      </tr>''';
    }).join('\n');

    final isOpen = session['status'] == 'open';

    final htmlContent = '''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>تقرير وردية - $shiftName</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap');
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Cairo',sans-serif;background:#fff;color:#263238;padding:28px;direction:rtl}
${_printHeaderCss()}
.meta{display:flex;gap:20px;background:#F0F7FF;border-radius:10px;padding:12px 16px;margin-bottom:18px;flex-wrap:wrap}
.meta-item label{font-size:10px;color:#90A4AE;display:block}
.meta-item span{font-size:13px;font-weight:700}
.summary{display:flex;background:linear-gradient(135deg,#0277BD,#01579B);border-radius:12px;padding:16px;margin-bottom:18px;color:#fff}
.sum-col{flex:1;text-align:center}
.sum-col .val{font-size:22px;font-weight:800}
.sum-col .lbl{font-size:11px;opacity:.8;margin-top:2px}
.divider{width:1px;background:rgba(255,255,255,.2)}
.section-title{font-size:13px;font-weight:800;color:#263238;margin-bottom:8px;margin-top:16px}
.pay-row{display:flex;align-items:center;gap:12px;background:#f9f9f9;border-radius:8px;padding:10px 14px;margin-bottom:7px}
.pay-label{font-weight:700;flex:1}
.pay-count{font-size:11px;color:#90A4AE}
.pay-total{font-weight:800;font-size:15px;min-width:80px;text-align:left}
table{width:100%;border-collapse:collapse;margin-top:8px}
thead tr{background:#0277BD;color:#fff}
thead th{padding:10px 14px;font-size:12px;text-align:right}
tbody tr:nth-child(even){background:#F0F7FF}
tbody td{padding:9px 14px;font-size:12px;border-bottom:1px solid #E0F0FF}
.footer{margin-top:20px;padding-top:14px;border-top:1px solid #E0F0FF;text-align:center;font-size:11px;color:#90A4AE}
@media print{body{padding:12px}}
</style>
</head>
<body>
${_printHeaderHtml(title: 'تقرير وردية: $shiftName', subtitle: isOpen ? 'وردية مفتوحة' : 'إغلاق وردية')}
<div class="meta">
  <div class="meta-item"><label>الوردية</label><span>$shiftName</span></div>
  <div class="meta-item"><label>الموظف</label><span>$userName</span></div>
  <div class="meta-item"><label>بداية الوردية</label><span>${_fmtDt(startDt)}</span></div>
  ${!isOpen ? '<div class="meta-item"><label>نهاية الوردية</label><span>${_fmtDt(endDt)}</span></div>' : ''}
  <div class="meta-item"><label>الحالة</label><span style="color:${isOpen ? '#4CAF50' : '#0277BD'}">${isOpen ? 'مفتوحة' : 'مغلقة'}</span></div>
</div>
<div class="summary">
  <div class="sum-col"><div class="val">${visits.length}</div><div class="lbl">إجمالي الزيارات</div></div>
  <div class="divider"></div>
  <div class="sum-col"><div class="val">${grandTotal.toStringAsFixed(0)} ج</div><div class="lbl">إجمالي الإيرادات</div></div>
</div>
<div class="section-title">تفصيل طرق الدفع</div>
${payBlock('كاش', countCash, totalCash, '#2E7D32')}
${payBlock('بنكك', countBank, totalBank, '#0277BD')}
${payBlock('فوري', countFwry, totalFwry, '#7B1FA2')}
${payBlock('اوكاش', countOkash, totalOkash, '#F57C00')}
${payBlock('ماي كاش', countMycash, totalMycash, '#0097A7')}
<div class="section-title">تفصيل الزيارات</div>
<table>
  <thead><tr><th>المريض</th><th>الوقت</th><th>طريقة الدفع</th><th>المبلغ</th></tr></thead>
  <tbody>$rows</tbody>
</table>
<div class="footer">مختبر الفادي — نظام إدارة المعمل © ${DateTime.now().year}</div>
<script>window.onload=function(){window.print()}</script>
</body></html>''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }


  /// طباعة مطالبة شركة معيّنة: تعرض كل مريض، التاريخ، رقم البطاقة (المسجّل في
  /// الزيارة نفسها)، الفحوصات وسعرها، قيمة الخصم (= المطالبة) على كل زيارة،
  /// وفي الأسفل إجمالي المطالبة الكلي المطلوب تحصيله من الشركة.
  void _printCompanyClaimReport({
    required Map<String, dynamic>? company,
    required List<Map<String, dynamic>> visits,
  }) {
    final companyName = company?['name'] ?? 'عام (بدون شركة)';
    final discountPercent = company?['discount_percent'];

    double grandClaim = 0;
    double grandValue = 0;

    final rows = visits.map((v) {
      final dt = DateTime.tryParse(v['date'] ?? '') ?? DateTime.now();
      final patient = _patientById(v['patient_id'] as int? ?? 0);
      final tests = _visitTestsForVisit(v['id'] as int);

      // رقم البطاقة مسجّل في الزيارة نفسها وقت الكشف
      final cardNumber = _cardNumberForVisit(v);

      final rowTotal = tests.fold<double>(
          0, (s, t) => s + (t['price_at_time'] as num? ?? 0).toDouble());
      // مبلغ المطالبة من الشركة = discount المسجّل في الزيارة فعلياً
      final claim = (v['discount'] as num? ?? 0).toDouble();

      grandClaim += claim;
      grandValue += rowTotal;

      final testsHtml = tests.isEmpty
          ? '—'
          : tests.map((t) => t['test_name'] ?? '').join('<br>');
      final pricesHtml = tests.isEmpty
          ? '—'
          : tests
              .map((t) =>
                  '${(t['price_at_time'] as num? ?? 0).toStringAsFixed(0)} ج')
              .join('<br>');

      return '''<tr>
        <td>${patient?['name'] ?? v['patient_name'] ?? '—'}</td>
        <td>${dt.day}/${dt.month}/${dt.year}</td>
        <td>$cardNumber</td>
        <td>$testsHtml</td>
        <td>$pricesHtml</td>
        <td style="font-weight:700;color:#0277BD">${rowTotal.toStringAsFixed(0)} ج</td>
        <td style="font-weight:800;color:#F57C00">${claim.toStringAsFixed(0)} ج</td>
      </tr>''';
    }).join('\n');

    final htmlContent = '''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>مطالبة شركة - $companyName</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap');
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Cairo',sans-serif;background:#fff;color:#263238;padding:28px;direction:rtl}
${_printHeaderCss()}
.meta{display:flex;gap:20px;background:#F0F7FF;border-radius:10px;padding:12px 16px;margin-bottom:18px;flex-wrap:wrap}
.meta-item label{font-size:10px;color:#90A4AE;display:block}
.meta-item span{font-size:13px;font-weight:700}
table{width:100%;border-collapse:collapse;margin-top:8px}
thead tr{background:#0277BD;color:#fff}
thead th{padding:10px 12px;font-size:12px;text-align:right}
tbody tr:nth-child(even){background:#F0F7FF}
tbody td{padding:9px 12px;font-size:12px;border-bottom:1px solid #E0F0FF;vertical-align:top;line-height:1.7}
.totals{margin-top:18px;display:flex;justify-content:flex-end;gap:14px}
.totals-box{background:linear-gradient(135deg,#0277BD,#01579B);border-radius:12px;padding:16px 24px;color:#fff;min-width:240px}
.totals-box.claim{background:linear-gradient(135deg,#F57C00,#E65100)}
.totals-row{display:flex;justify-content:space-between;font-size:13px;margin-bottom:6px}
.totals-row.final{font-size:17px;font-weight:800;border-top:1px solid rgba(255,255,255,.3);padding-top:8px;margin-top:6px}
.footer{margin-top:24px;padding-top:14px;border-top:1px solid #E0F0FF;text-align:center;font-size:11px;color:#90A4AE}
@media print{body{padding:12px}}
</style>
</head>
<body>
${_printHeaderHtml(title: 'مطالبة شركة: $companyName', subtitle: 'من ${_from.day}/${_from.month}/${_from.year} إلى ${_to.day}/${_to.month}/${_to.year}')}
<div class="meta">
  <div class="meta-item"><label>الشركة</label><span>$companyName</span></div>
  ${discountPercent != null ? '<div class="meta-item"><label>نسبة الخصم  </label><span>$discountPercent%</span></div>' : ''}
  <div class="meta-item"><label>عدد الزيارات</label><span>${visits.length}</span></div>
</div>
<table>
  <thead><tr>
    <th>اسم المريض</th><th>التاريخ</th><th>رقم البطاقة</th><th>الفحوصات</th><th>السعر</th><th>إجمالي الفحوصات</th><th>قيمة المطالبة</th>
  </tr></thead>
  <tbody>$rows</tbody>
</table>
<div class="totals">
  <div class="totals-box claim">
    <div class="totals-row final"><span>إجمالي المطالبة من الشركة</span><span>${grandClaim.toStringAsFixed(0)} ج</span></div>
  </div>
</div>
<div class="footer">مختبر الفادي — نظام إدارة المعمل © ${DateTime.now().year}</div>
<script>window.onload=function(){window.print()}</script>
</body></html>''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  // ─── empty state ──────────────────────────────────────────────────────────────

  Widget _emptyState(
          {IconData icon = Icons.bar_chart_rounded,
          String message = 'لا توجد بيانات للفترة المحددة'}) =>
      Center(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 48, color: _textHint),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  fontFamily: 'Cairo', color: _textSecondary)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Session Detail Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _SessionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> session;
  final List<Map<String, dynamic>> visits;
  final String shiftName;
  final String userName;
  final DateTime? startDt;
  final DateTime? endDt;
  final Map<String, dynamic>? Function(int) patientById;
  final Map<String, dynamic>? Function(int?) companyById;
  final List<Map<String, dynamic>> Function(int) visitTestsForVisit;
  final String Function(String) payLabel;
  final Color Function(String) payColor;
  final IconData Function(String) payIcon;
  final String Function(DateTime) fmtDt;
  final void Function(Map<String, dynamic>) onVisitTap;
  final VoidCallback onPrint;

  const _SessionDetailSheet({
    required this.session,
    required this.visits,
    required this.shiftName,
    required this.userName,
    required this.startDt,
    required this.endDt,
    required this.patientById,
    required this.companyById,
    required this.visitTestsForVisit,
    required this.payLabel,
    required this.payColor,
    required this.payIcon,
    required this.fmtDt,
    required this.onVisitTap,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = session['status'] == 'open';
    final totalRevenue =
        visits.fold(0.0, (s, v) => s + (v['total'] as num? ?? 0));

    final pmTotals = <String, double>{};
    final pmCounts = <String, int>{};
    for (final v in visits) {
      final pm = v['payment_method'] as String? ?? 'cash';
      final amt = (v['total'] as num? ?? 0).toDouble();
      pmTotals[pm] = (pmTotals[pm] ?? 0) + amt;
      pmCounts[pm] = (pmCounts[pm] ?? 0) + 1;
    }
    final activeMethods =
        pmTotals.keys.where((k) => (pmCounts[k] ?? 0) > 0).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shiftName,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Cairo',
                                      color: _primaryDark)),
                              Row(children: [
                                const Icon(Icons.person_outline_rounded,
                                    size: 13, color: _textHint),
                                const SizedBox(width: 4),
                                Text(userName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _textHint,
                                        fontFamily: 'Cairo')),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOpen
                                        ? const Color(0xFF4CAF50)
                                            .withOpacity(0.1)
                                        : _primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isOpen ? 'مفتوحة' : 'مغلقة',
                                    style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isOpen
                                            ? const Color(0xFF4CAF50)
                                            : _primary),
                                  ),
                                ),
                              ]),
                            ]),
                      ),
                      ElevatedButton.icon(
                        onPressed: onPrint,
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('طباعة PDF',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    // Times
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.login_rounded,
                            size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        Text(
                          startDt != null ? fmtDt(startDt!) : '—',
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        if (endDt != null) ...[
                          const SizedBox(width: 14),
                          const Icon(Icons.logout_rounded,
                              size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            fmtDt(endDt!),
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 10),
                    // Summary chips
                    Row(children: [
                      _chip(Icons.receipt_long_rounded,
                          '${visits.length} زيارة', _primary),
                      const SizedBox(width: 8),
                      _chip(Icons.payments_rounded,
                          '${totalRevenue.toStringAsFixed(0)} ج',
                          const Color(0xFF2E7D32)),
                    ]),
                    if (activeMethods.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      // Payment breakdown
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        ...activeMethods.map((m) {
                          final color = payColor(m);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(payIcon(m), color: color, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${payLabel(m)}: ${(pmTotals[m] ?? 0).toStringAsFixed(0)} ج (${pmCounts[m]} زيارة)',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color),
                              ),
                            ]),
                          );
                        }),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    const Divider(color: _divider),
                  ]),
            ),
            // Visits list
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final v = visits[i];
                  final dt = DateTime.tryParse(v['date'] ?? '');
                  final patient =
                      patientById(v['patient_id'] as int? ?? 0);
                  final tests = visitTestsForVisit(v['id'] as int);
                  final pm = v['payment_method'] as String? ?? '';
                  final pmColor = payColor(pm);

                  return InkWell(
                    onTap: () => onVisitTap(v),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _divider),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFE3F2FD),
                                child: Text(
                                  (patient?['name'] as String? ?? '?')[0],
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: _primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(patient?['name'] ?? '—',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Cairo',
                                              fontSize: 13,
                                              color: _textPrimary)),
                                      if (dt != null)
                                        Text(
                                            '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: _textHint,
                                                fontFamily: 'Cairo')),
                                    ]),
                              ),
                              Column(children: [
                                Text(
                                    '${(v['total'] as num? ?? 0).toStringAsFixed(0)} ج',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: _primary,
                                        fontFamily: 'Cairo')),
                                if (pm.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: pmColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      payLabel(pm),
                                      style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 10,
                                          color: pmColor,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ]),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_left_rounded,
                                  color: _textHint, size: 18),
                            ]),
                          ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Group Detail Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _GroupDetailSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> visits;
  final Map<String, dynamic>? Function(int) patientById;
  final Map<String, dynamic>? Function(int?) companyById;
  final List<Map<String, dynamic>> Function(int) visitTestsForVisit;
  final void Function(Map<String, dynamic>) onVisitTap;
  final String Function(String) payLabel;
  final Color Function(String) payColor;
  final IconData Function(String) payIcon;
  final String Function(DateTime) fmtDt;
  final bool canPrint;
  final VoidCallback? onPrint;

  const _GroupDetailSheet({
    required this.title,
    required this.visits,
    required this.patientById,
    required this.companyById,
    required this.visitTestsForVisit,
    required this.onVisitTap,
    required this.payLabel,
    required this.payColor,
    required this.payIcon,
    required this.fmtDt,
    this.canPrint = true,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final totalRevenue =
        visits.fold(0.0, (s, v) => s + (v['total'] as num? ?? 0));
    final totalDiscount =
        visits.fold(0.0, (s, v) => s + (v['discount'] as num? ?? 0));

    // Payment breakdown
    final pmTotals = <String, double>{};
    final pmCounts = <String, int>{};
    for (final v in visits) {
      final pm = v['payment_method'] as String? ?? 'cash';
      final amt = (v['total'] as num? ?? 0).toDouble();
      pmTotals[pm] = (pmTotals[pm] ?? 0) + amt;
      pmCounts[pm] = (pmCounts[pm] ?? 0) + 1;
    }
    final activeMethods =
        pmTotals.keys.where((k) => (pmCounts[k] ?? 0) > 0).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Cairo',
                                color: _primaryDark)),
                      ),
                      if (canPrint && onPrint != null)
                        ElevatedButton.icon(
                          onPressed: onPrint,
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('طباعة PDF',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _chip(Icons.medical_services_rounded,
                          '${visits.length} زيارة', _primary),
                      const SizedBox(width: 8),
                      _chip(Icons.payments_rounded,
                          '${totalRevenue.toStringAsFixed(0)} ج',
                          const Color(0xFF2E7D32)),
                      if (totalDiscount > 0) ...[
                        const SizedBox(width: 8),
                        _chip(
                            Icons.discount_rounded,
                            'خصم ${totalDiscount.toStringAsFixed(0)} ج',
                            const Color(0xFFF59E0B)),
                      ],
                    ]),
                    // Payment breakdown
                    if (activeMethods.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        ...activeMethods.map((m) {
                          final color = payColor(m);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: color.withOpacity(0.3)),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(payIcon(m), color: color, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${payLabel(m)}: ${(pmTotals[m] ?? 0).toStringAsFixed(0)} ج',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color),
                              ),
                            ]),
                          );
                        }),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    const Divider(color: _divider),
                  ]),
            ),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final v = visits[i];
                  final dt = DateTime.tryParse(v['date'] ?? '');
                  final patient = patientById(v['patient_id'] as int? ?? 0);
                  final tests = visitTestsForVisit(v['id'] as int);
                  final pm = v['payment_method'] as String? ?? '';
                  final pmColor = payColor(pm);

                  return InkWell(
                    onTap: () => onVisitTap(v),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _divider),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFE3F2FD),
                                child: Text(
                                  (patient?['name'] as String? ?? '?')[0],
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: _primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(patient?['name'] ?? '—',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Cairo',
                                              fontSize: 13,
                                              color: _textPrimary)),
                                      if (dt != null)
                                        Text(
                                            '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: _textHint,
                                                fontFamily: 'Cairo')),
                                    ]),
                              ),
                              Column(children: [
                                Text(
                                    '${(v['total'] as num? ?? 0).toStringAsFixed(0)} ج',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: _primary,
                                        fontFamily: 'Cairo')),
                                if ((v['discount'] as num? ?? 0) > 0)
                                  Text(
                                      'خصم ${(v['discount'] as num).toStringAsFixed(0)} ج',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFF59E0B),
                                          fontFamily: 'Cairo')),
                                if (pm.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: pmColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      payLabel(pm),
                                      style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 10,
                                          color: pmColor,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ]),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_left_rounded,
                                  color: _textHint, size: 18),
                            ]),
                            if (tests.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: tests.map((t) {
                                  final hasResult =
                                      (t['result'] as String?)?.isNotEmpty ==
                                          true;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: hasResult
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hasResult
                                                ? Icons.check_circle_outline
                                                : Icons
                                                    .hourglass_empty_rounded,
                                            size: 11,
                                            color: hasResult
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            t['test_name'] as String? ??
                                                'فحص',
                                            style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 11,
                                                color: hasResult
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(
                                                        0xFFF59E0B)),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${(t['price_at_time'] as num? ?? 0).toStringAsFixed(0)} ج',
                                            style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 10,
                                                color: _textHint),
                                          ),
                                        ]),
                                  );
                                }).toList(),
                              ),
                            ],
                          ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Visit Detail Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _VisitDetailSheet extends StatelessWidget {
  final Map<String, dynamic> visit;
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? company;
  final List<Map<String, dynamic>> tests;
  final DateTime? dt;
  final String Function(String) payLabel;
  final Color Function(String) payColor;
  final IconData Function(String) payIcon;
  final String Function(DateTime) fmtDt;

  const _VisitDetailSheet({
    required this.visit,
    required this.patient,
    required this.company,
    required this.tests,
    required this.dt,
    required this.payLabel,
    required this.payColor,
    required this.payIcon,
    required this.fmtDt,
  });

  @override
  Widget build(BuildContext context) {
    final total = (visit['total'] as num? ?? 0).toDouble();
    final discount = (visit['discount'] as num? ?? 0).toDouble();
    final paid = (visit['paid'] as num? ?? 0).toDouble();
    final remaining = total - paid;
    final pm = visit['payment_method'] as String? ?? '';
    final pmColor = payColor(pm);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: Text(
                        (patient?['name'] as String? ?? '?')[0],
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: _primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient?['name'] ?? '—',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Cairo',
                                    color: _primaryDark)),
                            if ((patient?['phone'] as String?)?.isNotEmpty ==
                                true)
                              Text(patient!['phone'],
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _textHint,
                                      fontFamily: 'Cairo')),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  const Divider(color: _divider),
                  const SizedBox(height: 10),
                  _infoRow(Icons.access_time_rounded, 'التاريخ والوقت',
                      dt != null
                          ? '${dt!.day}/${dt!.month}/${dt!.year}  ${dt!.hour.toString().padLeft(2, '0')}:${dt!.minute.toString().padLeft(2, '0')}'
                          : '—'),
                  if (company != null)
                    _infoRow(Icons.business_rounded, 'الشركة',
                        company!['name'] as String),
                  if ((visit['card_number'] as String?)?.isNotEmpty == true)
                    _infoRow(Icons.badge_outlined, 'رقم البطاقة',
                        visit['card_number'] as String),
                  // Payment method
                  if (pm.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Icon(payIcon(pm), size: 16, color: _primary),
                        const SizedBox(width: 8),
                        const Text('طريقة الدفع: ',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: _textHint)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: pmColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            payLabel(pm),
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: pmColor),
                          ),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _divider),
                    ),
                    child: Column(children: [
                      _finRow('الإجمالي', total, _primary),
                      if (discount > 0)
                        _finRow(
                            company != null ? 'مطالبة الشركة' : 'الخصم',
                            discount,
                            const Color(0xFFF59E0B)),
                      _finRow('المدفوع', paid, const Color(0xFF2E7D32)),
                      if (remaining > 0) ...[
                        const Divider(color: _divider, height: 16),
                        _finRow('المتبقي', remaining, Colors.red.shade400),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const Text('الفحوصات',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _textPrimary)),
                  const SizedBox(height: 8),
                  ...tests.map((t) {
                    final hasResult =
                        (t['result'] as String?)?.isNotEmpty == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _divider),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                    t['test_name'] as String? ?? 'فحص',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Cairo',
                                        color: _textPrimary)),
                              ),
                              Text(
                                  '${(t['price_at_time'] as num? ?? 0).toStringAsFixed(0)} ج',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                      color: _primary)),
                            ]),
                            const SizedBox(height: 6),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: hasResult
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        hasResult
                                            ? Icons.check_circle_outline
                                            : Icons.hourglass_empty_rounded,
                                        size: 12,
                                        color: hasResult
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                          hasResult
                                              ? 'تم إدخال النتيجة'
                                              : 'في الانتظار',
                                          style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 11,
                                              color: hasResult
                                                  ? const Color(0xFF2E7D32)
                                                  : const Color(0xFFF59E0B))),
                                    ]),
                              ),
                            ]),
                            if (hasResult) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _divider),
                                ),
                                child: Text(t['result'] as String,
                                    style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        color: _textPrimary)),
                              ),
                            ],
                          ]),
                    );
                  }),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 13, color: _textHint)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
        ]),
      );

  Widget _finRow(String label, double value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: _textSecondary)),
          const Spacer(),
          Text('${value.toStringAsFixed(0)} ج',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ]),
      );
}