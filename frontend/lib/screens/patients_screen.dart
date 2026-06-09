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
const _error = Color(0xFFEF4444);

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});
  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _companies = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _patients = List<Map<String, dynamic>>.from(await ApiService.getPatients());
    _companies = List<Map<String, dynamic>>.from(await ApiService.getCompanies());
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered => _patients.where((p) =>
    _search.isEmpty ||
    p['name'].toString().contains(_search) ||
    (p['phone'] ?? '').toString().contains(_search)
  ).toList();

  String _companyName(dynamic id) {
    if (id == null) return '—';
    final c = _companies.where((c) => c['id'] == id).firstOrNull;
    return c?['name'] ?? '—';
  }

  void _showVisitsDialog(Map<String, dynamic> patient) async {
    final visits = List<Map<String, dynamic>>.from(await ApiService.getVisitsByPatient(patient['id']));
    if (!mounted) return;
    showDialog(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: 600, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [_primary, _primaryDark])),
            child: Row(children: [
              const Icon(Icons.history_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('سجل زيارات ${patient['name']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                Text('${visits.length} زيارة', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo')),
              ])),
              IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          SizedBox(height: 400, child: visits.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.inbox_rounded, size: 48, color: _textHint),
                SizedBox(height: 12),
                Text('لا توجد زيارات', style: TextStyle(fontFamily: 'Cairo', color: _textSecondary)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final v = visits[i];
                  final dt = DateTime.tryParse(v['date'] ?? '') ?? DateTime.now();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _divider)),
                    child: Row(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.receipt_long_rounded, color: _primary, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${dt.day}/${dt.month}/${dt.year}', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary)),
                        Text(_payLabel(v['payment_method'] ?? ''), style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: _textSecondary)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${(v['total'] as num).toStringAsFixed(0)} جنيه', style: const TextStyle(fontWeight: FontWeight.w800, color: _primary, fontFamily: 'Cairo', fontSize: 15)),
                        if ((v['discount'] as num? ?? 0) > 0)
                          Text('خصم ${(v['discount'] as num).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontFamily: 'Cairo')),
                      ]),
                    ]),
                  );
                }),
          ),
        ])),
      ),
    ));
  }

  String _payLabel(String m) {
    switch (m) {
      case 'bank': return 'بنك فوري';
      case 'mycash': return 'ماي كاش';
      default: return 'كاش';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _divider, width: 2)), boxShadow: [BoxShadow(color: Color(0x0F0277BD), blurRadius: 12, offset: Offset(0, 2))]),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('المرضى', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDark, fontFamily: 'Cairo')),
            Text('${_patients.length} مريض مسجل', style: const TextStyle(fontSize: 12, color: _textHint, fontFamily: 'Cairo')),
          ]),
          const Spacer(),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _searchCtrl, onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'البحث باسم المريض أو رقم الهاتف...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo', color: _textHint),
                  prefixIcon: const Icon(Icons.search_rounded, color: _textHint),
                  suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18, color: _textHint), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }) : null,
                  filled: true, fillColor: _bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              )),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _divider, width: 1.5)),
                child: Text('${_filtered.length} نتيجة', style: const TextStyle(fontFamily: 'Cairo', color: _textSecondary, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF0F7FF), Color(0xFFE8F4FD)]), border: Border(bottom: BorderSide(color: _divider, width: 2))),
                child: const Row(children: [
                  Expanded(flex: 3, child: _H('المريض')),
                  Expanded(flex: 2, child: _H('رقم الهاتف')),
                  Expanded(flex: 1, child: _H('الجنس')),
                  Expanded(flex: 2, child: _H('الشركة')),
                  SizedBox(width: 80, child: _H('سجل', center: true)),
                ]),
              ),
              if (_loading) const Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: _primary))
              else if (_filtered.isEmpty) const Padding(padding: EdgeInsets.all(50), child: Column(children: [
                Icon(Icons.people_outline, size: 48, color: _textHint),
                SizedBox(height: 12),
                Text('لا يوجد مرضى', style: TextStyle(fontFamily: 'Cairo', color: _textSecondary, fontWeight: FontWeight.w700)),
              ]))
              else ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final p = _filtered[i];
                  final isFemale = p['gender'] == 'أنثى';
                  final company = _companyName(p['company_id']);
                  return Container(
                    decoration: BoxDecoration(color: i.isEven ? Colors.white : const Color(0xFFFAFCFF), border: const Border(bottom: BorderSide(color: _divider, width: 0.5))),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), child: Row(children: [
                      Expanded(flex: 3, child: Row(children: [
                        CircleAvatar(radius: 18, backgroundColor: isFemale ? const Color(0xFFFCE4EC) : const Color(0xFFE3F2FD),
                            child: Text((p['name'] as String)[0], style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: isFemale ? const Color(0xFFC2185B) : _primary))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary)),
                          Text('#${p['id']}', style: const TextStyle(fontSize: 11, color: _textHint, fontFamily: 'Cairo')),
                        ])),
                      ])),
                      Expanded(flex: 2, child: Text(p['phone'] ?? '—', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: _textSecondary))),
                      Expanded(flex: 1, child: Text(p['gender'] ?? '—', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: _textSecondary))),
                      Expanded(flex: 2, child: company == '—'
                        ? const Text('—', style: TextStyle(fontFamily: 'Cairo', color: _textHint))
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                            child: Text(company, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                          )),
                      SizedBox(width: 80, child: Center(child: Tooltip(message: 'عرض الزيارات', child: InkWell(
                        onTap: () => _showVisitsDialog(p),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.history_rounded, color: _primary, size: 16)),
                      )))),
                    ])),
                  );
                },
              ),
            ]),
          ),
        ]),
      )),
    ]));
  }
}

class _H extends StatelessWidget {
  final String text; final bool center;
  const _H(this.text, {this.center = false});
  @override Widget build(BuildContext context) => Text(text, textAlign: center ? TextAlign.center : TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo'));
}