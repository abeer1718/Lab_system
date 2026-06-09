import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;

  // Data
  List<Map<String, dynamic>> _visits = [];
  List<Map<String, dynamic>> _visitTests = [];
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _tests = [];

  // Filters
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _visits = List<Map<String, dynamic>>.from(await ApiService.getVisits());
    _visitTests = List<Map<String, dynamic>>.from(await ApiService.getAllVisitTests());
    _patients = List<Map<String, dynamic>>.from(await ApiService.getPatients());
    _companies = List<Map<String, dynamic>>.from(await ApiService.getCompanies());
    _tests = List<Map<String, dynamic>>.from(await ApiService.getTests());
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filteredVisits => _visits.where((v) {
    final dt = DateTime.tryParse(v['date'] ?? '');
    if (dt == null) return false;
    return dt.isAfter(_from.subtract(const Duration(days: 1))) && dt.isBefore(_to.add(const Duration(days: 1)));
  }).toList();

  double get _totalRevenue => _filteredVisits.fold(0, (s, v) => s + (v['total'] as num? ?? 0));
  double get _totalDiscount => _filteredVisits.fold(0, (s, v) => s + (v['discount'] as num? ?? 0));

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _divider, width: 2)), boxShadow: [BoxShadow(color: Color(0x0F0277BD), blurRadius: 12, offset: Offset(0, 2))]),
        child: const Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('التقارير', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDark, fontFamily: 'Cairo')),
            Text('تقارير شاملة عن نشاط المعمل', style: TextStyle(fontSize: 12, color: _textHint, fontFamily: 'Cairo')),
          ]),
        ]),
      ),
      if (_loading) const Expanded(child: Center(child: CircularProgressIndicator(color: _primary)))
      else Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Date filter
          _dateFilter(),
          const SizedBox(height: 16),
          // Summary cards
          _summaryCards(),
          const SizedBox(height: 20),
          // Tabs
          Container(
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              Container(
                decoration: const BoxDecoration(color: Color(0xFFF0F7FF), border: Border(bottom: BorderSide(color: _divider))),
                child: TabBar(
                  controller: _tabs,
                  labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500, fontSize: 13),
                  labelColor: _primary,
                  unselectedLabelColor: _textSecondary,
                  indicatorColor: _primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'الوردية'),
                    Tab(text: 'حسب الفحص'),
                    Tab(text: 'حسب المريض'),
                    Tab(text: 'حسب الشركة'),
                  ],
                ),
              ),
              SizedBox(height: 400, child: TabBarView(controller: _tabs, children: [
                _shiftReport(),
                _testReport(),
                _patientReport(),
                _companyReport(),
              ])),
            ]),
          ),
        ]),
      )),
    ]));
  }

  Widget _dateFilter() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
    child: Row(children: [
      const Icon(Icons.date_range_rounded, color: _primary, size: 20),
      const SizedBox(width: 10),
      const Text('الفترة الزمنية:', style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary)),
      const SizedBox(width: 16),
      _datePicker('من', _from, (d) => setState(() => _from = d)),
      const SizedBox(width: 12),
      _datePicker('إلى', _to, (d) => setState(() => _to = d)),
      const Spacer(),
      ...['اليوم', 'أسبوع', 'شهر'].map((l) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _to = now;
                if (l == 'اليوم') _from = DateTime(now.year, now.month, now.day);
                else if (l == 'أسبوع') _from = now.subtract(const Duration(days: 7));
                else _from = now.subtract(const Duration(days: 30));
              });
            },
            style: OutlinedButton.styleFrom(foregroundColor: _primary, side: const BorderSide(color: _divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            child: Text(l, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        );
      }),
    ]),
  );

  Widget _datePicker(String label, DateTime dt, ValueChanged<DateTime> onPick) => InkWell(
    onTap: () async {
      final picked = await showDatePicker(context: context, initialDate: dt, firstDate: DateTime(2020), lastDate: DateTime(2030));
      if (picked != null) onPick(picked);
    },
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _divider)),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 14, color: _primary),
        const SizedBox(width: 6),
        Text('$label: ${dt.day}/${dt.month}/${dt.year}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
      ]),
    ),
  );

  Widget _summaryCards() {
    final cards = [
      ('إجمالي الزيارات', '${_filteredVisits.length}', Icons.local_hospital_rounded, const Color(0xFF0277BD)),
      ('الإيرادات', '${_totalRevenue.toStringAsFixed(0)} ج', Icons.payments_rounded, const Color(0xFF2E7D32)),
      ('الخصومات', '${_totalDiscount.toStringAsFixed(0)} ج', Icons.discount_rounded, const Color(0xFFF59E0B)),
      ('المرضى', '${_patients.length}', Icons.people_rounded, const Color(0xFF8B5CF6)),
    ];
    return Row(children: cards.map((c) => Expanded(child: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: c.$4.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(c.$3, color: c.$4, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.$1, style: const TextStyle(fontSize: 12, color: _textHint, fontFamily: 'Cairo')),
            Text(c.$2, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.$4, fontFamily: 'Cairo')),
          ])),
        ]),
      ),
    ))).toList());
  }

  Widget _shiftReport() {
    // Group by date
    final Map<String, List<Map<String, dynamic>>> byDate = {};
    for (final v in _filteredVisits) {
      final dt = DateTime.tryParse(v['date'] ?? '') ?? DateTime.now();
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      byDate.putIfAbsent(key, () => []).add(v);
    }
    final sorted = byDate.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return sorted.isEmpty ? _emptyState() : ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final entry = sorted[i];
        final total = entry.value.fold(0.0, (s, v) => s + (v['total'] as num? ?? 0));
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _divider)),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.today_rounded, color: _primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary)),
              Text('${entry.value.length} زيارة', style: const TextStyle(fontSize: 12, color: _textHint, fontFamily: 'Cairo')),
            ])),
            Text('${total.toStringAsFixed(0)} ج', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _primary, fontFamily: 'Cairo')),
          ]),
        );
      },
    );
  }

  Widget _testReport() {
    // Count per test
    final Map<String, int> counts = {};
    final Map<String, double> revenues = {};
    for (final vt in _visitTests) {
      final name = vt['test_name'] ?? 'غير معروف';
      counts[name] = (counts[name] ?? 0) + 1;
      revenues[name] = (revenues[name] ?? 0) + (vt['price_at_time'] as num? ?? 0);
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.isEmpty ? _emptyState() : ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final e = sorted[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _divider)),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.science_outlined, color: _primary, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${e.value} مرة', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: _primary, fontSize: 13)),
              Text('${revenues[e.key]?.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: _textHint)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _patientReport() {
    final Map<int, List<Map<String, dynamic>>> byPatient = {};
    for (final v in _filteredVisits) {
      final pid = v['patient_id'] as int? ?? 0;
      byPatient.putIfAbsent(pid, () => []).add(v);
    }
    final sorted = byPatient.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    return sorted.isEmpty ? _emptyState() : ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final e = sorted[i];
        final p = _patients.where((p) => p['id'] == e.key).firstOrNull;
        final total = e.value.fold(0.0, (s, v) => s + (v['total'] as num? ?? 0));
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _divider)),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: const Color(0xFFE3F2FD), child: Text((p?['name'] as String? ?? '?')[0], style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: _primary))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p?['name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary)),
              Text(p?['phone'] ?? '', style: const TextStyle(fontSize: 11, color: _textHint, fontFamily: 'Cairo')),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${e.value.length} زيارة', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: _primary, fontSize: 13)),
              Text('${total.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: _textHint)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _companyReport() {
    final Map<int?, List<Map<String, dynamic>>> byCompany = {};
    for (final v in _filteredVisits) {
      final cid = v['company_id'] as int?;
      byCompany.putIfAbsent(cid, () => []).add(v);
    }
    final sorted = byCompany.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    return sorted.isEmpty ? _emptyState() : ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final e = sorted[i];
        final c = e.key == null ? null : _companies.where((c) => c['id'] == e.key).firstOrNull;
        final total = e.value.fold(0.0, (s, v) => s + (v['total'] as num? ?? 0));
        final discount = e.value.fold(0.0, (s, v) => s + (v['discount'] as num? ?? 0));
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _divider)),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.business_rounded, color: Color(0xFF2E7D32), size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c?['name'] ?? 'عام (بدون شركة)', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary)),
              if (discount > 0) Text('خصم: ${discount.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontFamily: 'Cairo')),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${e.value.length} زيارة', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: _primary, fontSize: 13)),
              Text('${total.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: _textHint)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _emptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.bar_chart_rounded, size: 48, color: _textHint),
    SizedBox(height: 12),
    Text('لا توجد بيانات للفترة المحددة', style: TextStyle(fontFamily: 'Cairo', color: _textSecondary)),
  ]));
}