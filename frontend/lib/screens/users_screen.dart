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

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _users = List<Map<String, dynamic>>.from(await ApiService.getUsers());
    setState(() => _loading = false);
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

  void _showDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: isEdit ? user['name'] : '');
    final userCtrl = TextEditingController(text: isEdit ? user['username'] : '');
    final passCtrl = TextEditingController();
    final emailCtrl = TextEditingController(text: isEdit ? (user['email'] ?? '') : '');
    String role = isEdit ? (user['role'] ?? 'reception') : 'reception';
    bool active = isEdit ? (user['active'] ?? true) : true;
    bool obscure = true;

    final roles = [
      ('admin', 'مدير النظام', Icons.admin_panel_settings_rounded),
      ('reception', 'موظف استقبال', Icons.support_agent_rounded),
      ('doctor', 'دكتور المعمل', Icons.vaccines_rounded),
    ];

    showDialog(context: context, barrierColor: Colors.black54, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Directionality(textDirection: TextDirection.rtl, child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: 520, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Text(isEdit ? 'تعديل مستخدم' : 'إضافة مستخدم جديد',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Cairo'))),
              IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24), child: Form(key: formKey, child: Column(children: [
            Row(children: [
              Expanded(child: _fld(nameCtrl, 'الاسم الكامل', Icons.person_outline, (v) => v!.trim().isEmpty ? 'مطلوب' : null)),
              const SizedBox(width: 14),
              Expanded(child: _fld(userCtrl, 'اسم المستخدم', Icons.alternate_email_rounded, (v) => v!.trim().isEmpty ? 'مطلوب' : null)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(
                controller: passCtrl,
                obscureText: obscure,
                validator: !isEdit ? (v) => v!.isEmpty ? 'مطلوب' : null : null,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  labelText: isEdit ? 'كلمة مرور جديدة (اختياري)' : 'كلمة المرور',
                  labelStyle: const TextStyle(fontFamily: 'Cairo', color: _textHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.lock_outline, color: _textHint, size: 20),
                  suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _textHint, size: 18), onPressed: () => setS(() => obscure = !obscure)),
                  filled: true, fillColor: _bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              )),
              const SizedBox(width: 14),
              Expanded(child: _fld(emailCtrl, 'البريد الإلكتروني', Icons.email_outlined, null, type: TextInputType.emailAddress)),
            ]),
            const SizedBox(height: 16),
            // Role selector
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('الدور', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo')),
              const SizedBox(height: 8),
              Row(children: roles.map((r) => Expanded(child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => setS(() => role = r.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: role == r.$1 ? const Color(0xFFE3F2FD) : _bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: role == r.$1 ? _primary : _divider, width: role == r.$1 ? 2 : 1.5),
                    ),
                    child: Column(children: [
                      Icon(r.$3, color: role == r.$1 ? _primary : _textHint, size: 22),
                      const SizedBox(height: 4),
                      Text(r.$2, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: role == r.$1 ? _primary : _textSecondary)),
                    ]),
                  ),
                ),
              ))).toList()),
            ]),
            const SizedBox(height: 16),
            if (isEdit) Row(children: [
              const Text('الحساب نشط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: _textSecondary)),
              const Spacer(),
              Switch(value: active, onChanged: (v) => setS(() => active = v), activeColor: _primary),
            ]),
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
                  try {
                    final data = {
                      'name': nameCtrl.text.trim(),
                      'username': userCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'role': role,
                      'active': active,
                      if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                    };
                    if (!isEdit) {
                      if (!data.containsKey('password')) { _showSnack('كلمة المرور مطلوبة', isError: true); return; }
                      await ApiService.addUser(data);
                      _showSnack('تمت الإضافة بنجاح');
                    } else {
                      await ApiService.updateUser(user['id'], data);
                      _showSnack('تم التعديل بنجاح');
                    }
                    _load();
                  } catch (e) { _showSnack('خطأ: $e', isError: true); }
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(isEdit ? 'حفظ' : 'إضافة', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ]),
          ])))),
        ])),
      )),
    ));
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

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return const Color(0xFF8B5CF6);
      case 'doctor': return const Color(0xFF2E7D32);
      default: return _primary;
    }
  }

  Color _roleBg(String role) {
    switch (role) {
      case 'admin': return const Color(0xFFF3E8FF);
      case 'doctor': return const Color(0xFFE8F5E9);
      default: return const Color(0xFFE3F2FD);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'مدير النظام';
      case 'doctor': return 'دكتور';
      default: return 'استقبال';
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
            const Text('المستخدمين والصلاحيات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDark, fontFamily: 'Cairo')),
            Text('${_users.length} مستخدم مسجل', style: const TextStyle(fontSize: 12, color: _textHint, fontFamily: 'Cairo')),
          ]),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showDialog(),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('إضافة مستخدم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11)),
          ),
        ]),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: _primary))
        : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF0F7FF), Color(0xFFE8F4FD)]), border: Border(bottom: BorderSide(color: _divider, width: 2))),
                child: const Row(children: [
                  Expanded(flex: 3, child: _H('المستخدم')),
                  Expanded(flex: 2, child: _H('اسم المستخدم')),
                  Expanded(flex: 2, child: _H('البريد')),
                  Expanded(flex: 2, child: _H('الدور')),
                  Expanded(flex: 1, child: _H('الحالة')),
                  SizedBox(width: 90, child: _H('إجراءات', center: true)),
                ]),
              ),
              if (_users.isEmpty) const Padding(padding: EdgeInsets.all(50), child: Column(children: [
                Icon(Icons.people_outline, size: 48, color: _textHint),
                SizedBox(height: 12),
                Text('لا يوجد مستخدمين', style: TextStyle(fontFamily: 'Cairo', color: _textSecondary, fontWeight: FontWeight.w700)),
              ]))
              else ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final isActive = u['active'] ?? true;
                  return Container(
                    decoration: BoxDecoration(color: i.isEven ? Colors.white : const Color(0xFFFAFCFF), border: const Border(bottom: BorderSide(color: _divider, width: 0.5))),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), child: Row(children: [
                      Expanded(flex: 3, child: Row(children: [
                        CircleAvatar(radius: 18, backgroundColor: _roleBg(u['role'] ?? ''),
                            child: Text((u['name'] as String? ?? '?')[0], style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: _roleColor(u['role'] ?? '')))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: _textPrimary)),
                          Text('#${u['id']}', style: const TextStyle(fontSize: 11, color: _textHint, fontFamily: 'Cairo')),
                        ])),
                      ])),
                      Expanded(flex: 2, child: Text(u['username'] ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: _textSecondary))),
                      Expanded(flex: 2, child: Text(u['email'] ?? '—', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: _textSecondary))),
                      Expanded(flex: 2, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _roleBg(u['role'] ?? ''), borderRadius: BorderRadius.circular(20)),
                        child: Text(_roleLabel(u['role'] ?? ''), textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: _roleColor(u['role'] ?? ''))),
                      )),
                      Expanded(flex: 1, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20)),
                        child: Text(isActive ? 'نشط' : 'موقوف', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? const Color(0xFF2E7D32) : _error)),
                      )),
                      SizedBox(width: 90, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _AB(Icons.edit_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD), 'تعديل', () => _showDialog(user: u)),
                        const SizedBox(width: 8),
                        _AB(Icons.delete_outline_rounded, _error, const Color(0xFFFFEBEE), 'حذف', () async {
                          await ApiService.deleteUser(u['id']);
                          _showSnack('تم الحذف');
                          _load();
                        }),
                      ])),
                    ])),
                  );
                },
              ),
            ]),
          ),
        )),
    ]));
  }
}

class _H extends StatelessWidget {
  final String text; final bool center;
  const _H(this.text, {this.center = false});
  @override Widget build(BuildContext context) => Text(text, textAlign: center ? TextAlign.center : TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo'));
}

class _AB extends StatelessWidget {
  final IconData icon; final Color color, bg; final String tip; final VoidCallback onTap;
  const _AB(this.icon, this.color, this.bg, this.tip, this.onTap);
  @override Widget build(BuildContext context) => Tooltip(message: tip, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16))));
}