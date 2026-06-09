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
// نموذج الفحص
// ═══════════════════════════════════════════════════════
class TestCategory {
  static const blood = 'دم';
  static const sugar = 'سكر';
  static const liver = 'كبد';
  static const kidney = 'كلى';
  static const hormones = 'هرمونات';
  static const other = 'أخرى';

  static Color colorFor(String category) {
    switch (category) {
      case blood: return const Color(0xFFEF4444);
      case sugar: return const Color(0xFFF59E0B);
      case liver: return const Color(0xFF8B5CF6);
      case kidney: return const Color(0xFF3B82F6);
      case hormones: return const Color(0xFFEC4899);
      default: return AppColors.primary;
    }
  }

  static List<String> get all => [blood, sugar, liver, kidney, hormones, other];
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
            Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Cairo'))),
          ],
        ),
        backgroundColor: isError ? AppColors.error : const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── ديالوج الإضافة / التعديل ────────────────────────
  void _showAddEditDialog({Map<String, dynamic>? test}) {
    final isEdit = test != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: isEdit ? test['name'] : '');
    final priceCtrl = TextEditingController(text: isEdit ? test['price'].toString() : '');
    final rangeCtrl = TextEditingController(text: isEdit ? (test['normal_range'] ?? '') : '');
    String selectedCat = isEdit ? (test['category'] ?? TestCategory.blood) : TestCategory.blood;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_rounded : Icons.add_circle_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'تعديل بيانات الفحص' : 'إضافة فحص جديد',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              isEdit ? 'عدّل البيانات ثم احفظ' : 'أدخل بيانات الفحص الجديد',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _buildFormField(
                          controller: nameCtrl,
                          label: 'اسم الفحص',
                          hint: 'مثال: صورة دم كاملة CBC',
                          icon: Icons.science_outlined,
                          validator: (v) => v!.trim().isEmpty ? 'اسم الفحص مطلوب' : null,
                        ),
                        const SizedBox(height: 16),
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
                                  if (double.tryParse(v) == null) return 'رقم غير صالح';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: rangeCtrl,
                          label: 'المدى الطبيعي',
                          hint: 'مثال: 70–100 mg/dL',
                          icon: Icons.straighten_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.divider, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              ),
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
                                    'price': double.parse(priceCtrl.text),
                                    'normal_range': rangeCtrl.text.trim(),
                                    'category': selectedCat,
                                  };
                                  if (!isEdit) {
                                    await ApiService.addTest(data);
                                    _showSnack('تمت إضافة الفحص بنجاح');
                                  } else {
                                    await ApiService.updateTest(test['id'], data);
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
                                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  // ─── ديالوج تأكيد الحذف ──────────────────────────────
  Future<void> _deleteTest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 34),
                ),
                const SizedBox(height: 20),
                const Text('تأكيد الحذف',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    )),
                const SizedBox(height: 12),
                const Text(
                  'هل أنت متأكد من حذف هذا الفحص؟\nلا يمكن التراجع عن هذا الإجراء.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                      ),
                      child: const Text('إلغاء',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('حذف',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                      ),
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
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
        boxShadow: [BoxShadow(color: Color(0x0F0277BD), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إدارة الفحوصات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDark, fontFamily: 'Cairo')),
            ],
          ),
          const Spacer(),
          // CircleAvatar(
          //   radius: 20,
          //   backgroundColor: AppColors.primary,
          //   child: const Text('م', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Cairo')),
          // ),
          // const SizedBox(width: 12),
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: const [
          //     Text('مدير النظام', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Cairo')),
          //     Text('admin@alfadi-lab.com', style: TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Cairo')),
          //   ],
          // ),
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
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))],
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
                hintStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textHint),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider, width: 1.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('إضافة فحص', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            ),
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
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFF0F7FF), Color(0xFFE8F4FD)]),
              border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: _TableHeader(text: 'اسم الفحص')),
                Expanded(flex: 3, child: _TableHeader(text: 'المدى الطبيعي')),
                Expanded(flex: 2, child: _TableHeader(text: 'السعر')),
                SizedBox(width: 100, child: _TableHeader(text: 'الإجراءات', center: true)),
              ],
            ),
          ),
          if (isLoading)
            const Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: AppColors.primary))
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
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
              child: Text(
                'عرض ${filteredTests.length} من ${tests.length} فحص',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontFamily: 'Cairo'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> test, int index) {
    final catColor = TestCategory.colorFor(test['category'] ?? '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFCFF),
        border: const Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: InkWell(
        hoverColor: const Color(0xFFE3F2FD),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.biotech_outlined, color: catColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(test['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary, fontFamily: 'Cairo')),
                          Text('#${test['id']}', style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  test['normal_range']?.isNotEmpty == true ? test['normal_range'] : 'غير محدد',
                  style: TextStyle(
                    fontSize: 12,
                    color: test['normal_range']?.isNotEmpty == true ? AppColors.textSecondary : AppColors.textHint,
                    fontFamily: 'Cairo',
                    fontStyle: test['normal_range']?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${(test['price'] as num).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Cairo'),
                      ),
                      const TextSpan(text: ' جنيه', style: TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(icon: Icons.edit_rounded, color: const Color(0xFF1565C0), bgColor: const Color(0xFFE3F2FD), tooltip: 'تعديل', onTap: () => _showAddEditDialog(test: test)),
                    const SizedBox(width: 8),
                    _ActionButton(icon: Icons.delete_outline_rounded, color: AppColors.error, bgColor: const Color(0xFFFFEBEE), tooltip: 'حذف', onTap: () => _deleteTest(test['id'])),
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
            decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
            child: const Icon(Icons.science_outlined, size: 40, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          const Text('لا توجد فحوصات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontFamily: 'Cairo')),
          const SizedBox(height: 6),
          const Text('أضف أول فحص الآن بالضغط على الزر أعلاه', style: TextStyle(fontSize: 13, color: AppColors.textHint, fontFamily: 'Cairo')),
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontFamily: 'Cairo')),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.textPrimary),
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.textHint, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontFamily: 'Cairo'),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.bgColor, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 17),
          ),
        ),
      );
}