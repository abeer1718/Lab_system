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

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});
  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
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
    _companies = List<Map<String, dynamic>>.from(await ApiService.getCompanies());
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered => _companies.where((c) =>
    _search.isEmpty || c['name'].toString().contains(_search)
  ).toList();

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? _error : const Color(0xFF1B5E20),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showDialog({Map<String, dynamic>? company}) {
    final isEdit = company != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: isEdit ? company['name'] : '');
    final discountCtrl = TextEditingController(text: isEdit ? company['discount_percent'].toString() : '0');
    final phoneCtrl = TextEditingController(text: isEdit ? (company['phone'] ?? '') : '');
    final addressCtrl = TextEditingController(text: isEdit ? (company['address'] ?? '') : '');

    showDialog(context: context, barrierColor: Colors.black54, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Icon(isEdit ? Icons.edit_rounded : Icons.business_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Text(isEdit ? 'تعديل الشركة' : 'إضافة شركة جديدة',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Cairo'))),
            IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(24), child: Form(key: formKey, child: Column(children: [
          _fld(nameCtrl, 'اسم الشركة', Icons.business_outlined, (v) => v!.trim().isEmpty ? 'مطلوب' : null),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _fld(discountCtrl, 'نسبة الخصم %', Icons.percent_rounded, (v) {
              if (v!.isEmpty) return 'مطلوب';
              final n = double.tryParse(v);
              if (n == null || n < 0 || n > 100) return '0-100 فقط';
              return null;
            }, type: TextInputType.number)),
            const SizedBox(width: 14),
            Expanded(child: _fld(phoneCtrl, 'رقم الهاتف', Icons.phone_outlined, null, type: TextInputType.phone)),
          ]),
          const SizedBox(height: 14),
          _fld(addressCtrl, 'العنوان', Icons.location_on_outlined, null),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: _textSecondary, side: const BorderSide(color: _divider, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final data = {
                  'name': nameCtrl.text.trim(),
                  'discount_percent': double.parse(discountCtrl.text),
                  'phone': phoneCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                };
                try {
                  if (!isEdit) { await ApiService.addCompany(data); _showSnack('تمت الإضافة بنجاح'); }
                  else { await ApiService.updateCompany(company['id'], data); _showSnack('تم التعديل بنجاح'); }
                  _load();
                } catch (e) { _showSnack('خطأ: $e', isError: true); }
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(isEdit ? 'حفظ' : 'إضافة', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ]),
        ]))),
      ])),
    ));
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, barrierColor: Colors.black54, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(width: 360, child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: _error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline_rounded, color: _error, size: 32)),
        const SizedBox(height: 16),
        const Text('تأكيد الحذف', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: _textPrimary)),
        const SizedBox(height: 10),
        const Text('هل تريد حذف هذه الشركة؟', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', color: _textSecondary)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), style: OutlinedButton.styleFrom(foregroundColor: _textSecondary, side: const BorderSide(color: _divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11)), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          ElevatedButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.delete_outline_rounded, size: 18), label: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)), style: ElevatedButton.styleFrom(backgroundColor: _error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11))),
        ]),
      ]))),
    ));
    if (ok == true) { await ApiService.deleteCompany(id); _showSnack('تم الحذف'); _load(); }
  }

  Widget _fld(TextEditingController c, String label, IconData icon, String? Function(String?)? v, {TextInputType? type}) => TextFormField(
    controller: c, validator: v, keyboardType: type,
    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
    decoration: InputDecoration(
      labelText: label, labelStyle: const TextStyle(fontFamily: 'Cairo', color: _textHint, fontSize: 13),
      prefixIcon: Icon(icon, color: _textHint, size: 20),
      filled: true, fillColor: _bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _divider, width: 2)), boxShadow: [BoxShadow(color: Color(0x0F0277BD), blurRadius: 12, offset: Offset(0, 2))]),
          child: Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('إدارة الشركات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDark, fontFamily: 'Cairo')),
              Text('الشركات المتعاقدة مع المعمل', style: TextStyle(fontSize: 12, color: _textHint, fontFamily: 'Cairo')),
            ]),
            const Spacer(),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            // Controls
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _searchCtrl, onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'البحث عن شركة...',
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
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showDialog(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('إضافة شركة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            // Table
            Container(
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF0F7FF), Color(0xFFE8F4FD)]), border: Border(bottom: BorderSide(color: _divider, width: 2))),
                  child: const Row(children: [
                    Expanded(flex: 3, child: _Hdr('اسم الشركة')),
                    Expanded(flex: 2, child: _Hdr('رقم الهاتف')),
                    Expanded(flex: 3, child: _Hdr('العنوان')),
                    Expanded(flex: 1, child: _Hdr('الخصم')),
                    SizedBox(width: 90, child: _Hdr('إجراءات', center: true)),
                  ]),
                ),
                if (_loading) const Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: _primary))
                else if (_filtered.isEmpty)
                  const Padding(padding: EdgeInsets.all(50), child: Column(children: [
                    Icon(Icons.business_outlined, size: 48, color: _textHint),
                    SizedBox(height: 12),
                    Text('لا توجد شركات', style: TextStyle(fontFamily: 'Cairo', color: _textSecondary, fontWeight: FontWeight.w700)),
                  ]))
                else ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final c = _filtered[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: i.isEven ? Colors.white : const Color(0xFFFAFCFF),
                        border: const Border(bottom: BorderSide(color: _divider, width: 0.5)),
                      ),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), child: Row(children: [
                        Expanded(flex: 3, child: Row(children: [
                          Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.business_rounded, color: _primary, size: 18)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary)),
                            Text('#${c['id']}', style: const TextStyle(fontSize: 11, color: _textHint, fontFamily: 'Cairo')),
                          ])),
                        ])),
                        Expanded(flex: 2, child: Text(c['phone'] ?? '—', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: _textSecondary))),
                        Expanded(flex: 3, child: Text(c['address'] ?? '—', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: _textSecondary))),
                        Expanded(flex: 1, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                          child: Text('${c['discount_percent']}%', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, color: Color(0xFF2E7D32), fontSize: 13)),
                        )),
                        SizedBox(width: 90, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _ActBtn(Icons.edit_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD), 'تعديل', () => _showDialog(company: c)),
                          const SizedBox(width: 8),
                          _ActBtn(Icons.delete_outline_rounded, _error, const Color(0xFFFFEBEE), 'حذف', () => _delete(c['id'])),
                        ])),
                      ])),
                    );
                  },
                ),
              ]),
            ),
          ]),
        )),
      ]),
    );
  }
}

class _Hdr extends StatelessWidget {
  final String text; final bool center;
  const _Hdr(this.text, {this.center = false});
  @override Widget build(BuildContext context) => Text(text, textAlign: center ? TextAlign.center : TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo'));
}

class _ActBtn extends StatelessWidget {
  final IconData icon; final Color color, bg; final String tip; final VoidCallback onTap;
  const _ActBtn(this.icon, this.color, this.bg, this.tip, this.onTap);
  @override Widget build(BuildContext context) => Tooltip(message: tip, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16))));
}