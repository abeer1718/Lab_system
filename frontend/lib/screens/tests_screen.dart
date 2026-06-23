import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════
// ثوابت الألوان والستايل
// ═══════════════════════════════════════════════════════
class AppColors {
  static const primary = Color(0xFF0277BD);
  static const primaryDark = Color(0xFF01579B);
  static const primaryLight = Color(0xFF0288D1);
  static const background = Color(0xFFF0F7FF);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF263238);
  static const textSecondary = Color(0xFF546E7A);
  static const textHint = Color(0xFF90A4AE);
  static const divider = Color(0xFFE0F0FF);
  static const error = Color(0xFFEF4444);
}

// ═══════════════════════════════════════════════════════
// نموذج الفحص الفرعي (Template)
// كل فحص فرعي عنده اسم ثابت + وحدة ثابتة + مدى طبيعي ثابت
// هذه القيم تُعرض كقراءة فقط عند إدخال النتائج، والمستخدم يدخل القيمة فقط
// ═══════════════════════════════════════════════════════
class SubTest {
  String name;
  String unit;
  String normalRange;

  SubTest({this.name = '', this.unit = '', this.normalRange = ''});

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'normalRange': normalRange,
      };

  factory SubTest.fromJson(Map<String, dynamic> j) => SubTest(
        name: j['name'] ?? '',
        unit: j['unit'] ?? '',
        normalRange: j['normalRange'] ?? '',
      );

  static List<SubTest> listFromTest(Map<String, dynamic> test) {
    final raw = test['subTests'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => SubTest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<Map<String, dynamic>> listToJson(List<SubTest> list) =>
      list.map((e) => e.toJson()).toList();
}

// ═══════════════════════════════════════════════════════
// الشاشة الرئيسية
// ═══════════════════════════════════════════════════════
class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  List<Map<String, dynamic>> tests = [];
  bool isLoading = true;
  String searchQuery = '';
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTests();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ─── تحميل البيانات ─────────────────────────────────
  Future<void> loadTests() async {
    setState(() => isLoading = true);
    try {
      tests = List<Map<String, dynamic>>.from(await ApiService.getTests());
    } catch (e) {
      _showSnack('خطأ في التحميل: $e', isError: true);
    }
    setState(() => isLoading = false);
  }

  // ─── فلترة الفحوصات ──────────────────────────────────
  List<Map<String, dynamic>> get filteredTests {
    return tests.where((t) {
      return searchQuery.isEmpty ||
          t['name'].toString().contains(searchQuery) ||
          t['price'].toString().contains(searchQuery);
    }).toList();
  }

  // ─── سناك بار ────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(fontFamily: 'Cairo'))),
          ],
        ),
        backgroundColor: isError ? AppColors.error : const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── ديالوج الإضافة / التعديل ────────────────────────
  void _showAddEditDialog({Map<String, dynamic>? test}) {
    final isEdit = test != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl  = TextEditingController(text: isEdit ? test['name'] : '');
    final priceCtrl = TextEditingController(
        text: isEdit ? test['price'].toString() : '');
    final rangeCtrl = TextEditingController(
        text: isEdit ? (test['normal_range'] ?? '') : '');
    final unitCtrl  = TextEditingController(
        text: isEdit ? (test['unit'] ?? '') : '');           // ← جديد

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Dialog Header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                            isEdit
                                ? Icons.edit_rounded
                                : Icons.add_circle_outline,
                            color: Colors.white,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? 'تعديل بيانات الفحص'
                                  : 'إضافة فحص جديد',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo'),
                            ),
                            Text(
                              isEdit
                                  ? 'عدّل البيانات ثم احفظ'
                                  : 'أدخل بيانات الفحص الجديد',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),

                // ── Dialog Body ──
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        // اسم الفحص
                        _buildFormField(
                          controller: nameCtrl,
                          label: 'اسم الفحص',
                          hint: 'مثال: صورة دم كاملة CBC',
                          icon: Icons.science_outlined,
                          validator: (v) =>
                              v!.trim().isEmpty ? 'اسم الفحص مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        // السعر + الوحدة في صف واحد
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: priceCtrl,
                                label: 'السعر (جنيه)',
                                hint: '150',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v!.trim().isEmpty) return 'السعر مطلوب';
                                  if (double.tryParse(v) == null)
                                    return 'رقم غير صالح';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildFormField(
                                controller: unitCtrl,
                                label: 'الوحدة (Unit)',
                                hint: 'mg/dL أو X10³/µL',
                                icon: Icons.straighten_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // المدى الطبيعي
                        _buildFormField(
                          controller: rangeCtrl,
                          label: 'المدى الطبيعي',
                          hint: 'مثال: 70–100 mg/dL',
                          icon: Icons.straighten_outlined,
                          maxLines: 2,
                        ),

                        // ── ملاحظة: الوحدة والمدى الطبيعي هنا تُستخدم فقط
                        //    لو الفحص ما عندوش فحوصات فرعية (subTests) ──
                        if (isEdit &&
                            SubTest.listFromTest(test).isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFFFE082)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 18, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'هذا الفحص عنده ${SubTest.listFromTest(test).length} فحص فرعي محفوظ. الوحدة والمدى الطبيعي أعلاه لن تُستخدم في إدخال النتائج.',
                                    style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // الأزرار
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(
                                      color: AppColors.divider, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 12)),
                              child: const Text('إلغاء',
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                Navigator.pop(ctx);
                                try {
                                  final data = {
                                    'name': nameCtrl.text.trim(),
                                    'price': double.parse(priceCtrl.text),
                                    'normal_range': rangeCtrl.text.trim(),
                                    'unit': unitCtrl.text.trim(),   // ← جديد
                                  };
                                  if (!isEdit) {
                                    await ApiService.addTest(data);
                                    _showSnack('تمت إضافة الفحص بنجاح');
                                  } else {
                                    await ApiService.updateTest(
                                        test['id'], data);
                                    _showSnack('تم تعديل الفحص بنجاح');
                                  }
                                  loadTests();
                                } catch (e) {
                                  _showSnack('خطأ: $e', isError: true);
                                }
                              },
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: Text(
                                isEdit ? 'حفظ التعديلات' : 'إضافة الفحص',
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
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
    );
  }

  // ─── ديالوج إدارة الفحوصات الفرعية (Template) ────────
  // هنا بيتعرّف الفحص الفرعي مرة واحدة: اسم + وحدة + مدى طبيعي
  // وبعد كده بيستخدم تلقائياً في شاشة إدخال النتائج
  // ─── ديالوج إدارة الفحوصات الفرعية (Template) ────────
  void _showSubTestsDialog(Map<String, dynamic> test) {
    List<SubTest> subTests = SubTest.listFromTest(test);
    if (subTests.isEmpty) {
      subTests = [SubTest()];
    } else {
      subTests = subTests
          .map((s) => SubTest(
                name: s.name,
                unit: s.unit,
                normalRange: s.normalRange))
          .toList();
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlg) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 850, // زيادة العرض عشان النصوص الطويلة
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.list_alt_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الفحوصات الفرعية',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo'),
                            ),
                            Text(
                              test['name'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx)),
                    ]),
                  ),

                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // رؤوس الأعمدة
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(children: [
                              const SizedBox(width: 30),
                              const Expanded(
                                  flex: 3,
                                  child: Text('اسم الفحص الفرعي',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint,
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700))),
                              const SizedBox(width: 8),
                              const Expanded(
                                  flex: 2,
                                  child: Text('الوحدة',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint,
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700))),
                              const SizedBox(width: 8),
                              const Expanded(
                                  flex: 3,  // زيادة للمدى الطبيعي
                                  child: Text('المدى الطبيعي',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint,
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700))),
                            ]),
                          ),

                          // قائمة الفحوصات الفرعية
                          ...List.generate(subTests.length, (i) {
                            final s = subTests[i];

                            final nameCtrl = TextEditingController(text: s.name);
                            nameCtrl.selection = TextSelection.collapsed(offset: s.name.length);

                            final unitCtrl = TextEditingController(text: s.unit);
                            unitCtrl.selection = TextSelection.collapsed(offset: s.unit.length);

                            final rangeCtrl = TextEditingController(text: s.normalRange);
                            rangeCtrl.selection = TextSelection.collapsed(offset: s.normalRange.length);

                            InputDecoration deco(String hint) => InputDecoration(
                                  hintText: hint,
                                  hintStyle: const TextStyle(
                                      fontFamily: 'Cairo',
                                      color: AppColors.textHint,
                                      fontSize: 12),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.divider)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.divider)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: SizedBox(
                                      width: 24,
                                      child: Text('${i + 1}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textHint)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // اسم الفحص الفرعي
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: nameCtrl,
                                      onChanged: (v) => s.name = v,
                                      textDirection: TextDirection.rtl,
                                      minLines: 1,
                                      maxLines: 3,
                                      keyboardType: TextInputType.multiline,
                                      style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary),
                                      decoration: deco('اسم الفحص الفرعي (مثال: TWBCS)'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // الوحدة
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: unitCtrl,
                                      onChanged: (v) => s.unit = v,
                                      textDirection: TextDirection.ltr,
                                      minLines: 1,
                                      maxLines: 3,
                                      keyboardType: TextInputType.multiline,
                                      style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 13,
                                          color: AppColors.textSecondary),
                                      decoration: deco('الوحدة (مثال: X10³/µL)'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // المدى الطبيعي (أكبر مساحة)
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: rangeCtrl,
                                      onChanged: (v) => s.normalRange = v,
                                      textDirection: TextDirection.ltr,
                                      minLines: 1,
                                      maxLines: 5,           // أكثر سطور
                                      keyboardType: TextInputType.multiline,
                                      style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 13,
                                          color: AppColors.textSecondary),
                                      decoration: deco('المدى الطبيعي (مثال: 70–100 mg/dL)'),
                                    ),
                                  ),

                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                                    onPressed: () => setDlg(() => subTests.removeAt(i)),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => setDlg(() => subTests.add(SubTest())),
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                            label: const Text('إضافة فحص فرعي جديد',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5)),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // أزرار الحفظ
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => setDlg(() => subTests = []),
                          icon: const Icon(Icons.clear_all_rounded, size: 18, color: AppColors.error),
                          label: const Text('مسح الكل',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final cleaned = subTests.where((s) => s.name.trim().isNotEmpty).toList();
                                final data = {
                                  'name': test['name'],
                                  'price': test['price'],
                                  'normal_range': test['normal_range'] ?? '',
                                  'unit': test['unit'] ?? '',
                                  'subTests': SubTest.listToJson(cleaned),
                                };
                                await ApiService.updateTest(test['id'], data);
                                _showSnack(cleaned.isEmpty
                                    ? 'تم إلغاء الفحوصات الفرعية'
                                    : 'تم حفظ الفحوصات الفرعية بنجاح');
                                loadTests();
                              },
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          );
        });
      },
    );
  }

  // ─── ديالوج تأكيد الحذف ──────────────────────────────
  Future<void> _deleteTest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 34),
                ),
                const SizedBox(height: 20),
                const Text('تأكيد الحذف',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo')),
                const SizedBox(height: 12),
                const Text(
                  'هل أنت متأكد من حذف هذا الفحص؟\nلا يمكن التراجع عن هذا الإجراء.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                      fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(
                              color: AppColors.divider, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 11)),
                      child: const Text('إلغاء',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('حذف',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteTest(id);
        _showSnack('تم حذف الفحص بنجاح');
        loadTests();
      } catch (e) {
        _showSnack('خطأ: $e', isError: true);
      }
    }
  }

  // ════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildControlsBar(),
                    const SizedBox(height: 20),
                    _buildTestsTable(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
            Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0F0277BD),
              blurRadius: 12,
              offset: Offset(0, 2))
        ],
      ),
      child: const Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إدارة الفحوصات',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      fontFamily: 'Cairo')),
            ],
          ),
          Spacer(),
        ],
      ),
    );
  }

  // ─── شريط التحكم (بحث + زر إضافة) ─────────────
  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => searchQuery = v),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'البحث عن فحص...',
                hintStyle: const TextStyle(
                    fontFamily: 'Cairo', color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textHint),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.textHint),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.divider, width: 1.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.divider, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('إضافة فحص',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 13)),
          ),
        ],
      ),
    );
  }

  // ─── الجدول ─────────────────────
  Widget _buildTestsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── رأس الجدول ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFF0F7FF), Color(0xFFE8F4FD)]),
              border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 2)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: _TableHeader(text: 'اسم الفحص')),
                Expanded(flex: 3, child: _TableHeader(text: 'المدى الطبيعي')),
                Expanded(flex: 2, child: _TableHeader(text: 'الوحدة')),  // ← جديد
                Expanded(flex: 2, child: _TableHeader(text: 'السعر')),
                SizedBox(
                    width: 140,
                    child: _TableHeader(text: 'الإجراءات', center: true)),
              ],
            ),
          ),

          if (isLoading)
            const Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(color: AppColors.primary))
          else if (filteredTests.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTests.length,
              itemBuilder: (_, i) => _buildTableRow(filteredTests[i], i),
            ),

          if (filteredTests.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: AppColors.divider))),
              child: Text(
                'عرض ${filteredTests.length} من ${tests.length} فحص',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontFamily: 'Cairo'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> test, int index) {
    final hasUnit = (test['unit'] as String? ?? '').isNotEmpty;
    final subTestsCount = SubTest.listFromTest(test).length;
    final hasSubTests = subTestsCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFCFF),
        border: const Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: InkWell(
        hoverColor: const Color(0xFFE3F2FD),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            children: [
              // اسم الفحص
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(test['name'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                        fontFamily: 'Cairo')),
                              ),
                              if (hasSubTests) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  child: Text(
                                    '$subTestsCount فرعي',
                                    style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2E7D32)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text('#${test['id']}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // المدى الطبيعي
              Expanded(
                flex: 3,
                child: hasSubTests
                    ? const Text('متعدد (فرعي)',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontFamily: 'Cairo',
                            fontStyle: FontStyle.italic))
                    : Text(
                        test['normal_range']?.isNotEmpty == true
                            ? test['normal_range']
                            : 'غير محدد',
                        style: TextStyle(
                            fontSize: 12,
                            color: test['normal_range']?.isNotEmpty == true
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                            fontFamily: 'Cairo',
                            fontStyle:
                                test['normal_range']?.isNotEmpty == true
                                    ? FontStyle.normal
                                    : FontStyle.italic),
                      ),
              ),

              // الوحدة ← جديد
              Expanded(
                flex: 2,
                child: hasSubTests
                    ? const Text('-',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontFamily: 'Cairo',
                            fontStyle: FontStyle.italic))
                    : hasUnit
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              test['unit'],
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontFamily: 'Cairo'),
                            ),
                          )
                        : const Text('-',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                                fontFamily: 'Cairo',
                                fontStyle: FontStyle.italic)),
              ),

              // السعر
              Expanded(
                flex: 2,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${(test['price'] as num).toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontFamily: 'Cairo'),
                      ),
                      const TextSpan(
                          text: ' جنيه',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ),

              // الإجراءات
              SizedBox(
                width: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                        icon: Icons.list_alt_rounded,
                        color: hasSubTests
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF6D4C41),
                        bgColor: hasSubTests
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFEFEBE9),
                        tooltip: 'الفحوصات الفرعية',
                        onTap: () => _showSubTestsDialog(test)),
                    const SizedBox(width: 6),
                    _ActionButton(
                        icon: Icons.edit_rounded,
                        color: const Color(0xFF1565C0),
                        bgColor: const Color(0xFFE3F2FD),
                        tooltip: 'تعديل',
                        onTap: () => _showAddEditDialog(test: test)),
                    const SizedBox(width: 6),
                    _ActionButton(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.error,
                        bgColor: const Color(0xFFFFEBEE),
                        tooltip: 'حذف',
                        onTap: () => _deleteTest(test['id'])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppColors.background, shape: BoxShape.circle),
            child: const Icon(Icons.science_outlined,
                size: 40, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          const Text('لا توجد فحوصات',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo')),
          const SizedBox(height: 6),
          const Text('أضف أول فحص الآن بالضغط على الزر أعلاه',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  // ─── هيلبرز ──────────────────────────────────────────
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo')),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textPrimary),
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(        
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          fontFamily: 'Cairo', color: AppColors.textHint, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.divider, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.divider, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.error, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ويدجيتات مساعدة
// ═══════════════════════════════════════════════════════
class _TableHeader extends StatelessWidget {
  final String text;
  final bool center;
  const _TableHeader({required this.text, this.center = false});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.right,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo'),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon,
      required this.color,
      required this.bgColor,
      required this.tooltip,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 17),
          ),
        ),
      );
}