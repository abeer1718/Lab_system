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

class DoctorScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const DoctorScreen({super.key, required this.currentUser});
  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  List<Map<String, dynamic>> _visits = [];
  List<Map<String, dynamic>> _patients = [];
  bool _loading = true;
  int? _selectedVisitId;
  List<Map<String, dynamic>> _visitTests = [];
  bool _loadingTests = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _visits = List<Map<String, dynamic>>.from(await ApiService.getVisits());
    _patients = List<Map<String, dynamic>>.from(await ApiService.getPatients());
    setState(() => _loading = false);
  }

  Future<void> _selectVisit(int visitId) async {
    setState(() { _selectedVisitId = visitId; _loadingTests = true; });
    _visitTests = List<Map<String, dynamic>>.from(await ApiService.getVisitTests(visitId));
    setState(() => _loadingTests = false);
  }

  String _patientName(dynamic id) {
    final p = _patients.where((p) => p['id'] == id).firstOrNull;
    return p?['name'] ?? '—';
  }

  bool _visitHasPending(Map<String, dynamic> v) {
    // We'll tag visits as pending when they have unfinished results
    // This is simplified — in production you'd join visit_tests
    return true; // will be filtered on server
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? _error : const Color(0xFF1B5E20),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showResultDialog(Map<String, dynamic> vt) {
    final ctrl = TextEditingController(text: vt['result'] ?? '');
    showDialog(context: context, barrierColor: Colors.black54, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), clipBehavior: Clip.antiAlias, child: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [_primary, _primaryDark])),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vt['test_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
              Text('المدى الطبيعي: ${vt['normal_range']?.isNotEmpty == true ? vt['normal_range'] : 'غير محدد'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo')),
            ])),
            IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('النتيجة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl, maxLines: 3, autofocus: true,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'أدخل نتيجة الفحص...',
              hintStyle: const TextStyle(fontFamily: 'Cairo', color: _textHint),
              filled: true, fillColor: _bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 2)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: _textSecondary, side: const BorderSide(color: _divider, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11)),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await ApiService.updateVisitTestResult(vt['id'], ctrl.text.trim());
                _showSnack('تم حفظ النتيجة');
                _selectVisit(_selectedVisitId!);
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11)),
            ),
          ]),
        ])),
      ]))),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _divider, width: 2)), boxShadow: [BoxShadow(color: Color(0x0F0277BD), blurRadius: 12, offset: Offset(0, 2))]),
        child: const Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('نتائج المعمل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDark, fontFamily: 'Cairo')),
            Text('إدخال نتائج الفحوصات', style: TextStyle(fontSize: 12, color: _textHint, fontFamily: 'Cairo')),
          ]),
        ]),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: _primary))
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // قائمة الزيارات
          SizedBox(width: 320, child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF0F7FF), Color(0xFFE8F4FD)]), border: Border(bottom: BorderSide(color: _divider))),
                child: Row(children: [
                  const Icon(Icons.list_alt_rounded, color: _primary, size: 20),
                  const SizedBox(width: 8),
                  Text('الزيارات (${_visits.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: _textPrimary)),
                ]),
              ),
              Expanded(child: _visits.isEmpty
                ? const Center(child: Text('لا توجد زيارات', style: TextStyle(fontFamily: 'Cairo', color: _textHint)))
                : ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: _visits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final v = _visits[i];
                    final isSelected = _selectedVisitId == v['id'];
                    final dt = DateTime.tryParse(v['date'] ?? '') ?? DateTime.now();
                    return GestureDetector(
                      onTap: () => _selectVisit(v['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE3F2FD) : _bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? _primary : _divider, width: isSelected ? 2 : 1),
                        ),
                        child: Row(children: [
                          CircleAvatar(radius: 18, backgroundColor: isSelected ? _primary : const Color(0xFFE3F2FD),
                              child: Text((v['patient_name'] as String? ?? '?')[0], style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: isSelected ? Colors.white : _primary, fontSize: 13))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(v['patient_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary, fontSize: 13)),
                            Text('${dt.day}/${dt.month}/${dt.year}', style: const TextStyle(fontSize: 11, color: _textHint, fontFamily: 'Cairo')),
                          ])),
                          Text('${(v['total'] as num).toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: _primary, fontSize: 12)),
                        ]),
                      ),
                    );
                  },
                )),
            ]),
          )),
          // الفحوصات
          Expanded(child: _selectedVisitId == null
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: _bg, shape: BoxShape.circle), child: const Icon(Icons.touch_app_rounded, size: 40, color: _textHint)),
                const SizedBox(height: 16),
                const Text('اختر زيارة لعرض فحوصاتها', style: TextStyle(fontFamily: 'Cairo', color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w700)),
              ]))
            : Container(
                margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF0F7FF), Color(0xFFE8F4FD)]), border: Border(bottom: BorderSide(color: _divider))),
                    child: Row(children: [
                      const Icon(Icons.science_rounded, color: _primary, size: 20),
                      const SizedBox(width: 8),
                      Text('فحوصات ${_visits.where((v) => v['id'] == _selectedVisitId).firstOrNull?['patient_name'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: _textPrimary)),
                    ]),
                  ),
                  Expanded(child: _loadingTests
                    ? const Center(child: CircularProgressIndicator(color: _primary))
                    : _visitTests.isEmpty
                      ? const Center(child: Text('لا توجد فحوصات', style: TextStyle(fontFamily: 'Cairo', color: _textHint)))
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _visitTests.length,
                        separatorBuilder: (_, __) => const Divider(color: _divider),
                        itemBuilder: (_, i) {
                          final t = _visitTests[i];
                          final hasResult = (t['result'] as String? ?? '').isNotEmpty;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(color: hasResult ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(hasResult ? Icons.check_circle_rounded : Icons.pending_rounded, color: hasResult ? const Color(0xFF2E7D32) : const Color(0xFFF59E0B), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t['test_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary)),
                                Text('المدى الطبيعي: ${t['normal_range']?.isNotEmpty == true ? t['normal_range'] : 'غير محدد'}',
                                    style: const TextStyle(fontSize: 11, color: _textHint, fontFamily: 'Cairo')),
                                if (hasResult)
                                  Text('النتيجة: ${t['result']}', style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                              ])),
                              ElevatedButton.icon(
                                onPressed: () => _showResultDialog(t),
                                icon: Icon(hasResult ? Icons.edit_rounded : Icons.add_rounded, size: 16),
                                label: Text(hasResult ? 'تعديل' : 'إدخال', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasResult ? const Color(0xFFE3F2FD) : _primary,
                                  foregroundColor: hasResult ? _primary : Colors.white,
                                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              ),
                            ]),
                          );
                        },
                      )),
                ]),
              )),
        ])),
    ]));
  }
}