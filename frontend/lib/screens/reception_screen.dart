import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class ReceptionScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic>? openSession;   // الوردية المفتوحة
  final VoidCallback? onSessionChanged;       // callback لتحديث الـ session

  const ReceptionScreen({
    super.key,
    required this.currentUser,
    this.openSession,
    this.onSessionChanged,
  });

  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();

}

class _ReceptionScreenState extends State<ReceptionScreen> {
  // ── State ──────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPatient;
  List<Map<String, dynamic>> _allTests = [];
  List<Map<String, dynamic>> _selectedTests = [];
  List<Map<String, dynamic>> _companies = [];
  bool _searching = false;
  bool _loadingTests = true;
  String _paymentMethod = 'cash';
  String _step = 'search'; // search | newPatient | selectTests | confirm

  // ── New patient form ───────────────────────────────
  final _patFormKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _secondNameCtrl = TextEditingController();
  final _thirdNameCtrl = TextEditingController();
  final _fourthNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();   
  String _gender = 'ذكر';
  int? _selectedCompanyId;

  @override
  void initState() {
    super.initState();
    _loadTests();
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _firstNameCtrl.dispose();
    _secondNameCtrl.dispose();
    _thirdNameCtrl.dispose();
    _fourthNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cardNumberCtrl.dispose();        
    super.dispose();
  }

  Future<void> _loadTests() async {
    _allTests = List<Map<String, dynamic>>.from(await ApiService.getTests());
    setState(() => _loadingTests = false);
  }

  Future<void> _loadCompanies() async {
    _companies =
        List<Map<String, dynamic>>.from(await ApiService.getCompanies());
    setState(() {});
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    _searchResults =
        List<Map<String, dynamic>>.from(await ApiService.searchPatients(q));
    setState(() => _searching = false);
  }

  double get _subtotal =>
      _selectedTests.fold(0, (s, t) => s + (t['price'] as num));

  double get _discount {
    if (_selectedPatient == null) return 0;
    final cid = _selectedPatient!['company_id'];
    if (cid == null) return 0;
    final company = _companies.where((c) => c['id'] == cid).firstOrNull;
    if (company == null) return 0;
    final pct = (company['discount_percent'] as num? ?? 0) / 100;
    return _subtotal * pct;
  }

  double get _total => _subtotal - _discount;

Future<void> _confirmVisit() async {
  // ── تحقق من وجود وردية مفتوحة ──────────────
  if (widget.openSession == null) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 380,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(color: const Color(0xFFFFF8E1), shape: BoxShape.circle),
                  child: const Icon(Icons.alarm_off_rounded, color: Color(0xFFF59E0B), size: 34),
                ),
                const SizedBox(height: 18),
                const Text('لا توجد وردية مفتوحة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: Color(0xFF263238))),
                const SizedBox(height: 10),
                const Text(
                  'يجب فتح وردية أولاً قبل تسجيل أي زيارة.\nاضغط على زر "بداية وردية" في القائمة الجانبية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Color(0xFF546E7A), height: 1.6),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
    return; // وقف التنفيذ
  }

  // ── بقية الكود الأصلي ──
  if (_selectedPatient == null || _selectedTests.isEmpty) return;
  final visitId = await ApiService.addVisit({
    'patient_id': _selectedPatient!['id'],
    'patient_name': _selectedPatient!['name'],
    'patient_gender': _selectedPatient!['gender'],   
    'date': DateTime.now().toIso8601String(),
    'payment_method': _total > 0 ? _paymentMethod : 'company',   // ← مهم    'subtotal': _subtotal,
    'discount': _discount,
    'total': _total,
    'paid': _total,           // ← طريقة الدفع = دافع كامل
    'company_id': _selectedPatient!['company_id'],
    'created_by': widget.currentUser['id'],
    'session_id': widget.openSession!['id'],  // ← ربط بالوردية
  });
    for (final t in _selectedTests) {
      await ApiService.addVisitTest({
        'visit_id': visitId,
        'test_id': t['id'],
        'test_name': t['name'],
        'normal_range': t['normal_range'] ?? '',
        'price_at_time': t['price'],
        'result': '',
      });
    }
    _showSnack('تم تسجيل الزيارة بنجاح');
    _resetAll();
  }

  void _resetAll() {
    setState(() {
      _step = 'search';
      _selectedPatient = null;
      _selectedTests = [];
      _searchCtrl.clear();
      _searchResults = [];
      _firstNameCtrl.clear();
      _secondNameCtrl.clear();
      _thirdNameCtrl.clear();
      _fourthNameCtrl.clear();
      _phoneCtrl.clear();
      _cardNumberCtrl.clear();        
      _paymentMethod = 'cash';
      _selectedCompanyId = null;
      _gender = 'ذكر';
    });
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

  // ══════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          _topBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _stepIndicator(),
                  const SizedBox(height: 20),
                  if (_step == 'search') _searchStep(),
                  if (_step == 'newPatient') _newPatientStep(),
                  if (_step == 'selectTests') _selectTestsStep(),
                  if (_step == 'confirm') _confirmStep(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────
  Widget _topBar() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: const BoxDecoration(
          color: _surface,
          border:
              Border(bottom: BorderSide(color: _divider, width: 2)),
          boxShadow: [
            BoxShadow(
                color: Color(0x0F0277BD),
                blurRadius: 12,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الاستقبال',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _primaryDark,
                        fontFamily: 'Cairo')),
                Text('تسجيل زيارة مريض جديدة',
                    style: TextStyle(
                        fontSize: 12,
                        color: _textHint,
                        fontFamily: 'Cairo')),
              ],
            ),
            const Spacer(),
            if (_selectedPatient != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.person_rounded,
                      size: 16, color: _primary),
                  const SizedBox(width: 6),
                  Text(_selectedPatient!['name'],
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color: _primary,
                          fontSize: 13)),
                ]),
              ),
          ],
        ),
      );

  // ─── Step Indicator ───────────────────────────────
  Widget _stepIndicator() {
    final steps = [
      ('search', 'البحث عن مريض', Icons.search_rounded),
      ('selectTests', 'اختيار الفحوصات', Icons.science_rounded),
      ('confirm', 'تأكيد ودفع', Icons.check_circle_rounded),
    ];
    final stepKeys = ['search', 'selectTests', 'confirm'];
    final currentIdx =
        stepKeys.indexOf(_step == 'newPatient' ? 'search' : _step);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 2))
          ]),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isDone = i < currentIdx;
          final isActive = i == currentIdx;
          final color = isDone || isActive ? _primary : _textHint;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                    child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDone
                            ? _primary
                            : isActive
                                ? const Color(0xFFE3F2FD)
                                : const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(color: _primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                          isDone
                              ? Icons.check_rounded
                              : steps[i].$3,
                          color: isDone ? Colors.white : color,
                          size: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(steps[i].$2,
                        style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Cairo',
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: color)),
                  ],
                )),
                if (i < steps.length - 1)
                  Container(
                      width: 40,
                      height: 2,
                      color: i < currentIdx ? _primary : _divider),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Search ───────────────────────────────
  Widget _searchStep() => Column(
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('البحث عن مريض',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        fontFamily: 'Cairo')),
                const SizedBox(height: 4),
                const Text('ابحث باسم المريض أو رقم هاتفه',
                    style: TextStyle(
                        fontSize: 12,
                        color: _textHint,
                        fontFamily: 'Cairo')),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 14),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'اسم المريض أو رقم الهاتف...',
                    hintStyle: const TextStyle(
                        fontFamily: 'Cairo', color: _textHint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: _textHint),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _primary)))
                        : null,
                    filled: true,
                    fillColor: _bg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _divider, width: 1.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _divider, width: 1.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...(_searchResults
                      .map((p) => _patientResultTile(p))),
                ],
                if (_searchCtrl.text.isNotEmpty &&
                    _searchResults.isEmpty &&
                    !_searching) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'لم يتم العثور على "${_searchCtrl.text}"',
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: Color(0xFF78350F)))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مريض جديد',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo',
                                  color: _textPrimary)),
                          Text('سجّل مريضاً جديداً في النظام',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _textHint,
                                  fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _step = 'newPatient'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('تسجيل مريض جديد',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _patientResultTile(Map<String, dynamic> p) {
    final company =
        _companies.where((c) => c['id'] == p['company_id']).firstOrNull;
    return InkWell(
      onTap: () => setState(() {
        _selectedPatient = p;
        _step = 'selectTests';
        _searchCtrl.clear();
        _searchResults = [];
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE3F2FD),
              child: Text((p['name'] as String)[0],
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      color: _primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: _textPrimary)),
                Text(p['phone'] ?? '',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _textHint,
                        fontFamily: 'Cairo')),
              ],
            )),
            if (company != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(company['name'],
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2E7D32),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_back_ios_new_rounded,
                size: 14, color: _textHint),
          ],
        ),
      ),
    );
  }

  // ─── Step: New Patient ────────────────────────────
  Widget _newPatientStep() => _card(
        child: Form(
          key: _patFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(children: [
                const Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تسجيل مريض جديد',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            fontFamily: 'Cairo')),
                    Text('أدخل بيانات المريض',
                        style: TextStyle(
                            fontSize: 12,
                            color: _textHint,
                            fontFamily: 'Cairo')),
                  ],
                )),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _step = 'search'),
                  icon: const Icon(Icons.arrow_forward_rounded,
                      size: 16),
                  label: const Text('رجوع',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Row 1: الاسم الأول + الاسم الثاني ──
              Row(children: [
                Expanded(
                    child: _field(
                        _firstNameCtrl,
                        'الاسم الأول',
                        Icons.person_outline,
                        (v) => v!.trim().isEmpty ? 'مطلوب' : null)),
                const SizedBox(width: 16),
                Expanded(
                    child: _field(
                        _secondNameCtrl,
                        'الاسم الثاني',
                        Icons.person_outline,
                        (v) => v!.trim().isEmpty ? 'مطلوب' : null)),
              ]),
              const SizedBox(height: 16),

              // ── Row 2: الاسم الثالث + الاسم الرابع ──
              Row(children: [
                Expanded(
                    child: _field(
                        _thirdNameCtrl,
                        'الاسم الثالث',
                        Icons.person_outline,
                        (v) => v!.trim().isEmpty ? 'مطلوب' : null)),
                const SizedBox(width: 16),
                Expanded(
                    child: _field(
                        _fourthNameCtrl,
                        'الاسم الرابع',
                        Icons.person_outline,
                        (v) => v!.trim().isEmpty ? 'مطلوب' : null)),
              ]),
              const SizedBox(height: 16),

              // ── Row 3: رقم الهاتف + الجنس ──
              Row(children: [
                Expanded(child: _phoneField()),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الجنس',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _textSecondary,
                              fontFamily: 'Cairo')),
                      const SizedBox(height: 7),
                      Row(
                          children: ['ذكر', 'أنثى']
                              .map((g) => Padding(
                                    padding:
                                        const EdgeInsets.only(left: 10),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _gender = g),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 150),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _gender == g
                                              ? _primary
                                              : _bg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: _gender == g
                                                  ? _primary
                                                  : _divider,
                                              width: 1.5),
                                        ),
                                        child: Text(g,
                                            style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: _gender == g
                                                    ? Colors.white
                                                    : _textSecondary)),
                                      ),
                                    ),
                                  ))
                              .toList()),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),

// ── الشركة + رقم البطاقة ──
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text('الشركة (اختياري)',
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
            fontFamily: 'Cairo')),
    const SizedBox(height: 7),
    DropdownButtonFormField<int?>(
      value: _selectedCompanyId,
      decoration: InputDecoration(
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _divider, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _divider, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: _textPrimary),
      hint: const Text('بدون شركة', style: TextStyle(fontFamily: 'Cairo', color: _textHint)),
      items: [
        const DropdownMenuItem(value: null, child: Text('بدون شركة')),
        ..._companies.map((c) => DropdownMenuItem(
              value: c['id'] as int,
              child: Text(c['name'], style: const TextStyle(fontFamily: 'Cairo')),
            )),
      ],
      onChanged: (v) {
        setState(() {
          _selectedCompanyId = v;
          if (v == null) _cardNumberCtrl.clear(); // تنظيف الحقل لو مافيش شركة
        });
      },
    ),

    // حقل رقم البطاقة - يظهر فقط لو مختار شركة
    if (_selectedCompanyId != null) ...[
      const SizedBox(height: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رقم البطاقة ',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                  fontFamily: 'Cairo')),
          const SizedBox(height: 7),
          TextFormField(
            controller: _cardNumberCtrl,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'رقم البطاقة مطلوب عند اختيار شركة';
              }
              return null;
            },
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'أدخل رقم البطاقة',
              hintStyle: const TextStyle(fontFamily: 'Cairo', color: _textHint),
              prefixIcon: const Icon(Icons.credit_card_outlined, color: _textHint, size: 20),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _error, width: 1.5)),
            ),
          ),
        ],
      ),
    ],
  ],
),
              const SizedBox(height: 24),

              // ── Submit ──
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!_patFormKey.currentState!.validate()) return;
                    final fullName =
                        '${_firstNameCtrl.text.trim()} ${_secondNameCtrl.text.trim()} ${_thirdNameCtrl.text.trim()} ${_fourthNameCtrl.text.trim()}';
final res = await ApiService.addPatient({
  'name': fullName,
  'first_name': _firstNameCtrl.text.trim(),
  'second_name': _secondNameCtrl.text.trim(),
  'third_name': _thirdNameCtrl.text.trim(),
  'fourth_name': _fourthNameCtrl.text.trim(),
  'phone': _phoneCtrl.text.trim(),
  'gender': _gender,
  'company_id': _selectedCompanyId,
  'card_number': _selectedCompanyId != null ? _cardNumberCtrl.text.trim() : null,   // ← أضف هذا السطر
  'created_at': DateTime.now().toIso8601String(),
});
                    final patient = await ApiService.getPatientById(
                        res['id'] as int);
                    if (patient != null) {
                      setState(() {
                        _selectedPatient = patient;
                        _step = 'selectTests';
                      });
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('تسجيل والمتابعة',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ]),
            ],
          ),
        ),
      );

  // ─── Step 2: Select Tests ─────────────────────────
  Widget _selectTestsStep() => Column(
        children: [
          _card(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'اختيار الفحوصات لـ ${_selectedPatient!['name']}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            fontFamily: 'Cairo')),
                    const Text('اختر الفحوصات المطلوبة',
                        style: TextStyle(
                            fontSize: 12,
                            color: _textHint,
                            fontFamily: 'Cairo')),
                  ],
                )),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _step = 'search';
                    _selectedTests = [];
                  }),
                  icon: const Icon(Icons.arrow_forward_rounded,
                      size: 16),
                  label: const Text('رجوع',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
              ]),
              const SizedBox(height: 16),
              if (_loadingTests)
                const Center(
                    child: CircularProgressIndicator(color: _primary))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allTests.map((t) {
                    final selected =
                        _selectedTests.any((s) => s['id'] == t['id']);
                    return FilterChip(
                      label: Text(
                          '${t['name']} — ${(t['price'] as num).toStringAsFixed(0)} جنيه',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : _textPrimary)),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v)
                          _selectedTests.add(t);
                        else
                          _selectedTests.removeWhere(
                              (s) => s['id'] == t['id']);
                      }),
                      selectedColor: _primary,
                      backgroundColor: _bg,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                          color: selected ? _primary : _divider,
                          width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                    );
                  }).toList(),
                ),
            ],
          )),
          if (_selectedTests.isNotEmpty) ...[
            const SizedBox(height: 16),
            _card(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الفحوصات المختارة',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        color: _textPrimary)),
                const SizedBox(height: 12),
                ..._selectedTests.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: _primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(t['name'],
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: _textPrimary))),
                        Text(
                            '${(t['price'] as num).toStringAsFixed(0)} جنيه',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                color: _primary)),
                      ]),
                    )),
                const Divider(color: _divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المجموع',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                            color: _textPrimary)),
                    Text('${_subtotal.toStringAsFixed(0)} جنيه',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _primary)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _step = 'confirm'),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 18),
                    label: const Text('المتابعة للدفع',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            )),
          ],
        ],
      );

  // ─── Step 3: Confirm & Pay ────────────────────────
  Widget _confirmStep() {
    final methods = [
      ('cash',   'كاش',     Icons.payments_outlined),
      ('bank',   'بنكك',    Icons.account_balance_outlined),
      ('fwry',   'فوري',    Icons.account_balance_outlined),
      ('okash',  'اوكاش',   Icons.account_balance_outlined),
      ('mycash', 'ماي كاشي', Icons.phone_iphone_outlined),
    ];
    return Column(children: [
      _card(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تأكيد الزيارة والدفع',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        fontFamily: 'Cairo')),
                Text('مريض: ${_selectedPatient!['name']}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _textHint,
                        fontFamily: 'Cairo')),
              ],
            )),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _step = 'selectTests'),
              icon: const Icon(Icons.arrow_forward_rounded,
                  size: 16),
              label: const Text('رجوع',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ]),
          const SizedBox(height: 20),

          // ── ملخص ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ..._selectedTests.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(t['name'],
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: _textSecondary))),
                        Text(
                            '${(t['price'] as num).toStringAsFixed(0)} جنيه',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: _textPrimary)),
                      ]),
                    )),
                const Divider(color: _divider),
                if (_discount > 0) ...[
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: _textSecondary)),
                        Text('${_subtotal.toStringAsFixed(0)} جنيه',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: _textSecondary)),
                      ]),
                  const SizedBox(height: 4),
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('خصم الشركة',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Color(0xFF2E7D32))),
                        Text(
                            '- ${_discount.toStringAsFixed(0)} جنيه',
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w700)),
                      ]),
                  const Divider(color: _divider),
                ],
                Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي النهائي',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _textPrimary)),
                      Text('${_total.toStringAsFixed(0)} جنيه',
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: _primary)),
                    ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── طريقة الدفع (تظهر فقط لو الإجمالي > 0) ──
          if (_total > 0) ...[
            const Text('طريقة الدفع',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                    color: _textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: methods.map((m) {
                final isSelected = _paymentMethod == m.$1;
                return Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _paymentMethod = m.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE3F2FD)
                            : _bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                isSelected ? _primary : _divider,
                            width: isSelected ? 2 : 1.5),
                      ),
                      child: Column(children: [
                        Icon(m.$3,
                            color: isSelected
                                ? _primary
                                : _textHint,
                            size: 22),
                        const SizedBox(height: 4),
                        Text(m.$2,
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? _primary
                                    : _textSecondary)),
                      ]),
                    ),
                  ),
                ));
              }).toList(),
            ),
            const SizedBox(height: 20),
          ] else ...[
            // رسالة عندما يكون الإجمالي صفر
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E7D32), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('تغطية كاملة من الشركة',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32))),

                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── تأكيد ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmVisit,
              icon: const Icon(Icons.check_circle_rounded,
                  size: 20),
              label: const Text('تأكيد وحفظ الزيارة',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      )),
    ]);
  }

  // ─── Helpers ──────────────────────────────────────
  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
        child: child,
      );

  /// حقل نصي عام
  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String? Function(String?)? validator, {
    TextInputType? type,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                  fontFamily: 'Cairo')),
          const SizedBox(height: 7),
          TextFormField(
            controller: ctrl,
            validator: validator,
            keyboardType: type,
            style:
                const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: _textHint,
                  fontSize: 13),
              prefixIcon: Icon(icon, color: _textHint, size: 20),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _divider, width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _divider, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _primary, width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _error, width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _error, width: 2)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ],
      );

  /// حقل رقم الهاتف — أرقام فقط، 10 خانات إلزامية
  Widget _phoneField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رقم الهاتف',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                  fontFamily: 'Cairo')),
          const SizedBox(height: 7),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.number,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style:
                const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'رقم الهاتف مطلوب';
              if (v.trim().length != 10)
                return 'يجب أن يكون 10 أرقام ';
              return null;
            },
            decoration: InputDecoration(
              hintText: '07XXXXXXXX',
              hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: _textHint,
                  fontSize: 13),
              prefixIcon: const Icon(Icons.phone_outlined,
                  color: _textHint, size: 20),
              counterText: '', // يخفي عداد الأحرف
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _divider, width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _divider, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _primary, width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _error, width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _error, width: 2)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ],
      );
}