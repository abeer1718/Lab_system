import 'package:flutter/material.dart';
import '../services/api_service.dart';

const _primary    = Color(0xFF0277BD);
const _primaryDark = Color(0xFF01579B);
const _bg         = Color(0xFFF0F7FF);
const _surface    = Colors.white;
const _textPrimary   = Color(0xFF263238);
const _textSecondary = Color(0xFF546E7A);
const _textHint   = Color(0xFF90A4AE);
const _divider    = Color(0xFFE0F0FF);
const _error      = Color(0xFFEF4444);

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});
  @override State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  List<Map<String, dynamic>> _shifts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _shifts = List<Map<String, dynamic>>.from(await ApiService.getShifts());
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

  // ─── حساب مدة الوردية ────────────────────────────
  String _duration(String start, String end) {
    int toMin(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }
    int diff = toMin(end) - toMin(start);
    if (diff <= 0) diff += 24 * 60; // تعدي منتصف الليل
    final h = diff ~/ 60;
    final m = diff % 60;
    return m == 0 ? '$h ساعة' : '$h س $m د';
  }

  // ─── ديالوج الإضافة/التعديل ───────────────────────
  void _showDialog({Map<String, dynamic>? shift}) {
    final isEdit = shift != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: isEdit ? shift['name'] : '');
    TimeOfDay startTime = isEdit
        ? _parseTime(shift['start_time'])
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = isEdit
        ? _parseTime(shift['end_time'])
        : const TimeOfDay(hour: 16, minute: 0);

    // ألوان الورديات
    final colors = [
      const Color(0xFF0277BD), // أزرق
      const Color(0xFF2E7D32), // أخضر
      const Color(0xFF8B5CF6), // بنفسجي
      const Color(0xFFF59E0B), // أصفر
      const Color(0xFFEF4444), // أحمر
      const Color(0xFF0891B2), // سماوي
    ];
    int selectedColor = isEdit
        ? colors.indexWhere((c) => c.value == (shift['color'] as int? ?? colors[0].value))
        : 0;
    if (selectedColor == -1) selectedColor = 0;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Row(children: [
                Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: Icon(isEdit ? Icons.edit_rounded : Icons.add_alarm_rounded, color: Colors.white, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEdit ? 'تعديل الوردية' : 'إضافة وردية جديدة',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                  const Text('حدد اسم الوردية وأوقاتها',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo')),
                ])),
                IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            Padding(padding: const EdgeInsets.all(24), child: Form(key: formKey, child: Column(children: [
              // اسم الوردية
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('اسم الوردية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo')),
                const SizedBox(height: 7),
                TextFormField(
                  controller: nameCtrl,
                  validator: (v) => v!.trim().isEmpty ? 'الاسم مطلوب' : null,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'مثال: وردية الصباح',
                    hintStyle: const TextStyle(fontFamily: 'Cairo', color: _textHint, fontSize: 13),
                    prefixIcon: const Icon(Icons.label_outline_rounded, color: _textHint, size: 20),
                    filled: true, fillColor: _bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              // وقت البداية والنهاية
              Row(children: [
                Expanded(child: _timePicker(
                  label: 'وقت البداية',
                  icon: Icons.login_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  time: startTime,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx, initialTime: startTime,
                      builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
                    );
                    if (picked != null) setS(() => startTime = picked);
                  },
                )),
                const SizedBox(width: 16),
                Expanded(child: _timePicker(
                  label: 'وقت النهاية',
                  icon: Icons.logout_rounded,
                  iconColor: _error,
                  time: endTime,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx, initialTime: endTime,
                      builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
                    );
                    if (picked != null) setS(() => endTime = picked);
                  },
                )),
              ]),
              const SizedBox(height: 16),
              // المدة المحسوبة
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.timelapse_rounded, color: _primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'مدة الوردية: ${_duration(_formatTime(startTime), _formatTime(endTime))}',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: _primary),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              // اختيار اللون
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('لون الوردية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo')),
                const SizedBox(height: 10),
                Row(children: List.generate(colors.length, (i) => Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: GestureDetector(
                    onTap: () => setS(() => selectedColor = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: colors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == i ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selectedColor == i ? [BoxShadow(color: colors[i].withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null,
                      ),
                      child: selectedColor == i
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                ))),
              ]),
              const SizedBox(height: 24),
              // أزرار
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(foregroundColor: _textSecondary, side: const BorderSide(color: _divider, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
// ─── داخل ElevatedButton.icon (في onPressed) ─────────────────────
onPressed: () async {
  if (!formKey.currentState!.validate()) return;

  final newName = nameCtrl.text.trim();
  final newStart = _formatTime(startTime);
  final newEnd = _formatTime(endTime);

  // === التحقق من التكرار عند الإضافة فقط ===
  if (!isEdit) {
    final exists = _shifts.any((shift) =>
        shift['name'].toString().trim().toLowerCase() == newName.toLowerCase() &&
        shift['start_time'] == newStart &&
        shift['end_time'] == newEnd);

    if (exists) {
      _showSnack('هذه الوردية موجودة مسبقاً بنفس الاسم والمدة', isError: true);
      return; // يمنع الإضافة
    }
  }

  Navigator.pop(ctx);

  final data = {
    'name': newName,
    'start_time': newStart,
    'end_time': newEnd,
    'color': colors[selectedColor].value,
  };

  try {
    if (!isEdit) {
      await ApiService.addShift(data);
      _showSnack('تمت إضافة الوردية بنجاح');
    } else {
      await ApiService.updateShift(shift['id'], data);
      _showSnack('تم تعديل الوردية بنجاح');
    }
    _load();
  } catch (e) {
    _showSnack('خطأ: $e', isError: true);
  }
},
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة الوردية',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                ),
              ]),
            ]))),
          ])),
        ),
      )),
    );
  }

  // ─── هيلبر وقت ────────────────────────────────────
  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _timePicker({required String label, required IconData icon, required Color iconColor, required TimeOfDay time, required VoidCallback onTap}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo')),
      const SizedBox(height: 7),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _bg, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _divider, width: 1.5),
          ),
          child: Row(children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(_formatTime(time), style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15, color: _textPrimary)),
            const Spacer(),
            const Icon(Icons.edit_rounded, color: _textHint, size: 16),
          ]),
        ),
      ),
    ]);
  }

  // ─── ديالوج تأكيد الحذف ──────────────────────────
  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, barrierColor: Colors.black54, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: SizedBox(width: 360, child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: _error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline_rounded, color: _error, size: 32)),
        const SizedBox(height: 16),
        const Text('حذف الوردية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: _textPrimary)),
        const SizedBox(height: 10),
        const Text('هل تريد حذف هذه الوردية؟', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', color: _textSecondary)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(foregroundColor: _textSecondary, side: const BorderSide(color: _divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11)),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          ElevatedButton.icon(onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: _error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11))),
        ]),
      ])))),
    ));
    if (ok == true) { await ApiService.deleteShift(id); _showSnack('تم حذف الوردية'); _load(); }
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Column(children: [
      // Top bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _divider, width: 2)), boxShadow: [BoxShadow(color: Color(0x0F0277BD), blurRadius: 12, offset: Offset(0, 2))]),
        child: Row(children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('إدارة الورديات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primaryDark, fontFamily: 'Cairo')),
            Text('حدد الورديات وأوقاتها', style: TextStyle(fontSize: 12, color: _textHint, fontFamily: 'Cairo')),
          ]),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showDialog(),
            icon: const Icon(Icons.add_alarm_rounded, size: 20),
            label: const Text('إضافة وردية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13)),
          ),
        ]),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: _primary))
        : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
 
            if (_shifts.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
                child: const Column(children: [
                  Icon(Icons.alarm_off_rounded, size: 56, color: _textHint),
                  SizedBox(height: 14),
                  Text('لا توجد ورديات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo')),
                  SizedBox(height: 6),
                  Text('أضف أول وردية الآن', style: TextStyle(fontSize: 13, color: _textHint, fontFamily: 'Cairo')),
                ]),
              )
            else
              // Timeline view
              _buildTimeline(),
          ]),
        )),
    ]));
  }

  Widget _buildTimeline() {
    return Column(children: [
      // الجدول
      Container(
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF0F7FF), Color(0xFFE8F4FD)]), border: Border(bottom: BorderSide(color: _divider, width: 2))),
            child: const Row(children: [
              SizedBox(width: 12),
              Expanded(flex: 3, child: _H('اسم الوردية')),
              Expanded(flex: 2, child: _H('البداية')),
              Expanded(flex: 2, child: _H('النهاية')),
              Expanded(flex: 2, child: _H('المدة')),
              SizedBox(width: 90, child: _H('إجراءات', center: true)),
            ]),
          ),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: _shifts.length,
            itemBuilder: (_, i) {
              final s = _shifts[i];
              final color = Color(s['color'] as int? ?? _primary.value);
              final duration = _duration(s['start_time'], s['end_time']);
              return Container(
                decoration: BoxDecoration(
                  color: i.isEven ? Colors.white : const Color(0xFFFAFCFF),
                  border: const Border(bottom: BorderSide(color: _divider, width: 0.5)),
                ),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16), child: Row(children: [
                  // مؤشر اللون
                  Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.access_time_rounded, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: _textPrimary, fontSize: 14)),
                      Text('#${s['id']}', style: const TextStyle(fontSize: 11, color: _textHint, fontFamily: 'Cairo')),
                    ])),
                  ])),
                  Expanded(flex: 2, child: _timeChip(s['start_time'], const Color(0xFF2E7D32), const Color(0xFFE8F5E9))),
                  Expanded(flex: 2, child: _timeChip(s['end_time'], _error, const Color(0xFFFFEBEE))),
                  Expanded(flex: 2, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(duration, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: color, fontSize: 12)),
                  )),
                  SizedBox(width: 90, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _ActBtn(Icons.edit_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD), 'تعديل', () => _showDialog(shift: s)),
                    const SizedBox(width: 8),
                    _ActBtn(Icons.delete_outline_rounded, _error, const Color(0xFFFFEBEE), 'حذف', () => _delete(s['id'])),
                  ])),
                ])),
              );
            },
          ),
        ]),
      ),
      const SizedBox(height: 20),
      // شريط التغطية التصويري
      _buildCoverageBar(),
    ]);
  }

  Widget _timeChip(String time, Color textColor, Color bgColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.schedule_rounded, size: 13, color: textColor),
      const SizedBox(width: 4),
      Text(time, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: textColor, fontSize: 13)),
    ]),
  );

  // ─── شريط تغطية ٢٤ ساعة ──────────────────────────
  Widget _buildCoverageBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.timeline_rounded, color: _primary, size: 20),
          SizedBox(width: 8),
          // Text('تغطية ٢٤ ساعة', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: _textPrimary)),
        ]),
        const SizedBox(height: 16),
        // الشريط
        SizedBox(height: 44, child: LayoutBuilder(builder: (ctx, constraints) {
          final totalWidth = constraints.maxWidth;
          return Stack(children: [
            // خلفية
            Container(
              width: totalWidth, height: 44,
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
            ),
            // الورديات
            ..._shifts.map((s) {
              final startMin = _timeToMinutes(s['start_time']);
              final endMin = _timeToMinutes(s['end_time']);
              final color = Color(s['color'] as int? ?? _primary.value);
              double startFrac = startMin / (24 * 60);
              double endFrac = endMin / (24 * 60);
              double width;
              double left;
              if (endFrac > startFrac) {
                left = startFrac * totalWidth;
                width = (endFrac - startFrac) * totalWidth;
              } else {
                // تعدي منتصف الليل — ارسمها كجزأين لكن هنا نبسط
                left = startFrac * totalWidth;
                width = (1 - startFrac + endFrac) * totalWidth;
                if (left + width > totalWidth) width = totalWidth - left;
              }
              return Positioned(
                right: totalWidth - left - width, // RTL
                top: 4, bottom: 4,
                width: width.clamp(2, totalWidth),
                child: Tooltip(
                  message: '${s['name']}: ${s['start_time']} - ${s['end_time']}',
                  child: Container(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                    child: width > 60 ? Center(child: Text(s['name'], style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)) : null,
                  ),
                ),
              );
            }),
            // علامات الساعات
            ...List.generate(9, (i) {
              final hour = i * 3;
              final frac = hour / 24;
              return Positioned(
                right: (1 - frac) * totalWidth - 1,
                top: 0, bottom: 0,
                child: Container(width: 1, color: Colors.white38),
              );
            }),
          ]);
        })),
        const SizedBox(height: 8),
        // تسميات الساعات
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(9, (i) {
          final hour = i * 3;
          return Text('${hour.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 10, color: _textHint, fontFamily: 'Cairo'));
        })),
        const SizedBox(height: 14),
        // Legend
        Wrap(spacing: 12, runSpacing: 8, children: _shifts.map((s) {
          final color = Color(s['color'] as int? ?? _primary.value);
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 5),
            Text(s['name'], style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: _textSecondary)),
          ]);
        }).toList()),
      ]),
    );
  }

  int _timeToMinutes(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}

// ─── Helpers ─────────────────────────────────────────
class _H extends StatelessWidget {
  final String text; final bool center;
  const _H(this.text, {this.center = false});
  @override Widget build(BuildContext context) => Text(text, textAlign: center ? TextAlign.center : TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSecondary, fontFamily: 'Cairo'));
}

class _ActBtn extends StatelessWidget {
  final IconData icon; final Color color, bg; final String tip; final VoidCallback onTap;
  const _ActBtn(this.icon, this.color, this.bg, this.tip, this.onTap);
  @override Widget build(BuildContext context) => Tooltip(message: tip, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16))));
}