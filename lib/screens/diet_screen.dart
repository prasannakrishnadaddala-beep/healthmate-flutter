import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});
  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  DateTime _date = DateTime.now();
  List<dynamic> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      final data = await ApiService.getDiet(dateStr);
      if (mounted) setState(() { _entries = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalCal => _entries.fold(0, (s, e) => s + ((e['calories'] ?? 0) as int));
  int get _totalWater => _entries.fold(0, (s, e) => s + ((e['water_ml'] ?? 0) as int));

  static const _meals = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
  static const _mealColors = {
    'Breakfast': HMColors.breakfast,
    'Lunch': HMColors.lunch,
    'Snack': HMColors.snack,
    'Dinner': HMColors.dinner,
  };
  static const _mealIcons = {
    'Breakfast': '🌅', 'Lunch': '☀️', 'Snack': '🍎', 'Dinner': '🌙',
  };

  void _showAddMeal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMealSheet(date: DateFormat('yyyy-MM-dd').format(_date), onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HMColors.bg,
      appBar: AppBar(
        title: const Text('Diet & Nutrition'),
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart_rounded), onPressed: () => _showAIAnalysis()),
          IconButton(icon: const Icon(Icons.email_rounded), onPressed: () => _sendEmail()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMeal,
        backgroundColor: HMColors.accent,
        foregroundColor: const Color(0xFF001a1a),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Meal', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: HMColors.accent,
        backgroundColor: HMColors.surface,
        child: CustomScrollView(
          slivers: [
            // Date picker
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: HMColors.text2),
                  onPressed: () { setState(() => _date = _date.subtract(const Duration(days: 1))); _load(); },
                ),
                Expanded(child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context, initialDate: _date,
                      firstDate: DateTime(2020), lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(primary: HMColors.accent, surface: HMColors.surface)),
                        child: child!,
                      ),
                    );
                    if (picked != null) { setState(() => _date = picked); _load(); }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: HMColors.surface, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: HMColors.border2),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: HMColors.accent),
                      const SizedBox(width: 8),
                      Text(DateFormat('EEE, MMM d, yyyy').format(_date),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: HMColors.text)),
                    ]),
                  ),
                )),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: HMColors.text2),
                  onPressed: _date.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                      ? () { setState(() => _date = _date.add(const Duration(days: 1))); _load(); }
                      : null,
                ),
              ]),
            )),

            // Stats
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                Expanded(child: HMStatCard(
                  label: 'Calories', value: _totalCal.toString(),
                  unit: 'kcal today', valueColor: HMColors.accent,
                  progress: _totalCal / 2000, progressColor: HMColors.accent,
                )),
                const SizedBox(width: 10),
                Expanded(child: HMStatCard(
                  label: 'Water', value: _totalWater.toString(),
                  unit: 'ml (${(_totalWater / 250).floor()} cups)', valueColor: HMColors.accent2,
                )),
                const SizedBox(width: 10),
                Expanded(child: HMStatCard(
                  label: 'Meals', value: _entries.length.toString(),
                  unit: 'logged', valueColor: HMColors.success,
                  badge: _entries.length >= 3 ? 'Good' : null, badgeColor: HMColors.success,
                )),
              ]),
            )),

            // Meal sections
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  for (int i = 0; i < 4; i++) ...[
                    const HMShimmerBox(height: 80),
                    const SizedBox(height: 10),
                  ],
                ])),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _meals.map((meal) {
                      final items = _entries.where((e) => e['meal_type'] == meal).toList();
                      final color = _mealColors[meal]!;
                      final mealCal = items.fold<int>(0, (s, e) => s + ((e['calories'] ?? 0) as int));
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: HMColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: HMColors.border),
                          ),
                          child: Column(children: [
                            // Meal header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                border: Border(bottom: BorderSide(
                                    color: items.isNotEmpty ? color.withOpacity(0.2) : Colors.transparent)),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: color.withOpacity(0.25)),
                                  ),
                                  child: Center(child: Text(_mealIcons[meal]!, style: const TextStyle(fontSize: 18))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(meal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HMColors.text)),
                                  Text('${items.length} item${items.length != 1 ? 's' : ''}',
                                      style: const TextStyle(fontSize: 11, color: HMColors.text3)),
                                ])),
                                Text('$mealCal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                                    color: color, fontFamily: 'DM Mono')),
                                Text(' kcal', style: const TextStyle(fontSize: 11, color: HMColors.text3)),
                              ]),
                            ),

                            // Items
                            if (items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text('Nothing logged yet',
                                    style: const TextStyle(fontSize: 13, color: HMColors.text3)),
                              )
                            else
                              ...List.generate(items.length, (i) {
                                final e = items[i] as Map<String, dynamic>;
                                Map<String, dynamic>? nutrients;
                                try {
                                  if ((e['notes'] ?? '').toString().startsWith('{')) {
                                    nutrients = Map<String, dynamic>.from(
                                        Uri.splitQueryString(e['notes']));
                                  }
                                } catch (_) {}

                                return Container(
                                  decoration: BoxDecoration(
                                    border: i < items.length - 1
                                        ? const Border(bottom: BorderSide(color: HMColors.border))
                                        : null,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Text(e['food_items'] ?? '—',
                                        style: const TextStyle(fontSize: 13, color: HMColors.text)),
                                    subtitle: Text('${e['calories'] ?? 0} kcal'
                                        + (e['water_ml'] != null && e['water_ml'] > 0 ? ' · 💧${e['water_ml']}ml' : ''),
                                        style: TextStyle(fontSize: 12, color: color)),
                                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, size: 16, color: HMColors.text3),
                                        onPressed: () => _showEditMeal(e),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_rounded, size: 16, color: HMColors.text3),
                                        onPressed: () => _deleteMeal(e['id']),
                                      ),
                                    ]),
                                  ),
                                );
                              }),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMeal(int id) async {
    try {
      await ApiService.deleteDiet(id);
      _load();
    } catch (e) {
      if (mounted) showHMToast(context, e.toString(), isError: true);
    }
  }

  void _showEditMeal(Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditMealSheet(entry: entry, onSaved: _load),
    );
  }

  Future<void> _showAIAnalysis() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: HMColors.surface,
        content: Row(children: [
          CircularProgressIndicator(color: HMColors.accent),
          SizedBox(width: 16),
          Text('Analyzing your diet...', style: TextStyle(color: HMColors.text)),
        ]),
      ),
    );
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      final result = await ApiService.getDietAnalysis(dateStr);
      if (!mounted) return;
      Navigator.pop(context);
      _showAnalysisDialog(result['analysis'] ?? 'No analysis available.');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showHMToast(context, e.toString(), isError: true);
    }
  }

  void _showAnalysisDialog(String analysis) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.95, expand: false,
        builder: (_, ctrl) => Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: HMColors.text3, borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('🤖', style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Text('AI Dietician Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: HMColors.text)),
              ])),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Text(analysis, style: const TextStyle(fontSize: 14, color: HMColors.text2, height: 1.7)),
          )),
        ]),
      ),
    );
  }

  Future<void> _sendEmail() async {
    try {
      await ApiService.sendDietEmail();
      if (mounted) showHMToast(context, 'Diet report sent to your email ✓');
    } catch (e) {
      if (mounted) showHMToast(context, e.toString(), isError: true);
    }
  }
}

// ── Add Meal Bottom Sheet ─────────────────────────────────────────────────────
class _AddMealSheet extends StatefulWidget {
  final String date;
  final VoidCallback onSaved;
  const _AddMealSheet({required this.date, required this.onSaved});

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _foodCtrl  = TextEditingController();
  final _calCtrl   = TextEditingController();
  final _waterCtrl = TextEditingController();
  String _mealType = 'Breakfast';
  bool _loading = false;
  bool _analyzing = false;
  Map<String, dynamic>? _nutrition;

  Future<void> _analyze() async {
    if (_foodCtrl.text.trim().isEmpty) return;
    setState(() => _analyzing = true);
    try {
      final r = await ApiService.analyzeNutrition(_foodCtrl.text.trim());
      if (mounted) {
        setState(() {
          _nutrition = r;
          _calCtrl.text = r['calories']?.toString() ?? '';
          _analyzing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;
    setState(() => _analyzing = true);
    try {
      final r = await ApiService.analyzeFoodPhoto(File(picked.path));
      if (mounted) {
        setState(() {
          _nutrition = r;
          if (r['food_items'] != null) _foodCtrl.text = r['food_items'];
          if (r['calories'] != null) _calCtrl.text = r['calories'].toString();
          if (r['meal_type'] != null) _mealType = r['meal_type'];
          _analyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _analyzing = false);
        showHMToast(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _save() async {
    if (_foodCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.addDiet({
        'date': widget.date, 'meal_type': _mealType,
        'food_items': _foodCtrl.text.trim(),
        'calories': int.tryParse(_calCtrl.text) ?? 0,
        'water_ml': int.tryParse(_waterCtrl.text) ?? 0,
        'notes': _nutrition != null ? _nutrition.toString() : '',
      });
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) {
      if (mounted) showHMToast(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: HMColors.text3, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Log Meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
          const SizedBox(height: 16),

          // Meal type selector
          const Text('MEAL TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: HMColors.text3, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(children: ['Breakfast', 'Lunch', 'Snack', 'Dinner'].map((m) {
            final sel = m == _mealType;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _mealType = m),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? HMColors.accent.withOpacity(0.15) : HMColors.bg3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? HMColors.accent : HMColors.border2),
                ),
                child: Text(m, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: sel ? HMColors.accent : HMColors.text3)),
              ),
            ));
          }).toList()),
          const SizedBox(height: 16),

          // Food items
          HMTextField(label: 'Food Items', hint: 'e.g. 2 idlis + sambar', controller: _foodCtrl, maxLines: 2),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: HMButton(
              label: _analyzing ? 'Analyzing...' : '✨ Analyze',
              onTap: _analyzing ? null : _analyze, loading: _analyzing,
              outlined: true,
            )),
            const SizedBox(width: 8),
            Expanded(child: HMButton(
              label: '📸 Photo', onTap: _pickPhoto,
              color: HMColors.accent2, outlined: true,
            )),
          ]),

          // Nutrition result
          if (_nutrition != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HMColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HMColors.success.withOpacity(0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_nutrition!['calories'] ?? 0} kcal — ${_nutrition!['breakdown'] ?? ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HMColors.success)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  NutrientBadge(label: 'P', value: '${_nutrition!['protein_g'] ?? 0}g', color: const Color(0xFF3b82f6)),
                  NutrientBadge(label: 'C', value: '${_nutrition!['carbs_g'] ?? 0}g', color: const Color(0xFFf59e0b)),
                  NutrientBadge(label: 'F', value: '${_nutrition!['fat_g'] ?? 0}g', color: const Color(0xFFef4444)),
                  NutrientBadge(label: 'Fiber', value: '${_nutrition!['fiber_g'] ?? 0}g', color: const Color(0xFF22c55e)),
                ]),
                if (_nutrition!['health_note'] != null) ...[
                  const SizedBox(height: 6),
                  Text('💡 ${_nutrition!['health_note']}',
                      style: const TextStyle(fontSize: 11, color: HMColors.text2)),
                ],
              ]),
            ),
          ],

          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: HMTextField(label: 'Calories (kcal)', hint: '0',
                controller: _calCtrl, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: HMTextField(label: 'Water (ml)', hint: '0',
                controller: _waterCtrl, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
              child: HMButton(label: 'Log Meal', onTap: _save, loading: _loading, icon: Icons.check_rounded)),
        ]),
      ),
    );
  }
}

// ── Edit Meal Sheet ───────────────────────────────────────────────────────────
class _EditMealSheet extends StatefulWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onSaved;
  const _EditMealSheet({required this.entry, required this.onSaved});

  @override
  State<_EditMealSheet> createState() => _EditMealSheetState();
}

class _EditMealSheetState extends State<_EditMealSheet> {
  late TextEditingController _foodCtrl;
  late TextEditingController _calCtrl;
  late TextEditingController _waterCtrl;
  late String _mealType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _foodCtrl  = TextEditingController(text: widget.entry['food_items'] ?? '');
    _calCtrl   = TextEditingController(text: '${widget.entry['calories'] ?? 0}');
    _waterCtrl = TextEditingController(text: '${widget.entry['water_ml'] ?? 0}');
    _mealType  = widget.entry['meal_type'] ?? 'Breakfast';
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiService.updateDiet(widget.entry['id'], {
        'food_items': _foodCtrl.text.trim(),
        'meal_type': _mealType,
        'calories': int.tryParse(_calCtrl.text) ?? 0,
        'water_ml': int.tryParse(_waterCtrl.text) ?? 0,
      });
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) {
      if (mounted) showHMToast(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: HMColors.text3, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Edit Meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
          const SizedBox(height: 16),
          Row(children: ['Breakfast', 'Lunch', 'Snack', 'Dinner'].map((m) {
            final sel = m == _mealType;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _mealType = m),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? HMColors.accent.withOpacity(0.15) : HMColors.bg3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? HMColors.accent : HMColors.border2),
                ),
                child: Text(m, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: sel ? HMColors.accent : HMColors.text3)),
              ),
            ));
          }).toList()),
          const SizedBox(height: 16),
          HMTextField(label: 'Food Items', controller: _foodCtrl, maxLines: 2),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: HMTextField(label: 'Calories (kcal)', controller: _calCtrl,
                keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: HMTextField(label: 'Water (ml)', controller: _waterCtrl,
                keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
              child: HMButton(label: 'Save Changes', onTap: _save, loading: _loading)),
        ]),
      ),
    );
  }
}
