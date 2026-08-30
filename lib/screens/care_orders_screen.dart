import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_symbols_icons/symbols.dart';

import '../app_theme.dart';
import '../classes/care_order.dart';
import '../classes/database_manager.dart';
import '../classes/patient.dart';
import '../classes/staff.dart';

// An order queued up for saving — not yet written to the database. Tapping
// its chip opens _OrderDetailSheet to fill in directions/duration; saving
// the whole screen writes one care_order row per pending order.
class _PendingOrder {
  final String label;
  final OrderCategory category;
  String directions;
  String? frequency;
  int? durationDays; // null = ongoing, no end date

  _PendingOrder({required this.label, required this.category, required this.directions});
}

// Jumps straight to composing orders — no list-first screen in the way.
// Tap presets to queue them, type anything not covered, tap a queued chip
// to add directions/duration/frequency, then save the whole batch at once.
class CareOrdersScreen extends StatefulWidget {
  final Patient patient;

  const CareOrdersScreen({super.key, required this.patient});

  @override
  State<CareOrdersScreen> createState() => _CareOrdersScreenState();
}

class _CareOrdersScreenState extends State<CareOrdersScreen> {
  final List<_PendingOrder> _pending = [];
  final TextEditingController _customController = TextEditingController();
  String? _staffId;
  bool _saving = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addPreset(OrderCategory category, String label) {
    if (_pending.any((o) => o.label == label)) return;
    setState(() => _pending.add(_PendingOrder(label: label, category: category, directions: label)));
  }

  void _addCustom() {
    final String text = _customController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _pending.add(_PendingOrder(label: text, category: OrderCategory.observation, directions: text));
      _customController.clear();
    });
  }

  void _removePending(_PendingOrder order) {
    setState(() => _pending.remove(order));
  }

  Future<void> _openDetail(_PendingOrder order) async {
    final bool? changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.clinicalWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _OrderDetailSheet(order: order),
    );
    if (changed == true) setState(() {});
  }

  Future<void> _showHistory() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _OrderHistorySheet(patient: widget.patient),
    );
  }

  Future<void> _saveAll() async {
    if (_pending.isEmpty || _staffId == null) return;
    setState(() => _saving = true);
    final DateTime now = DateTime.now();
    for (final order in _pending) {
      await DatabaseManager().insertCareOrder(
        patientUuid: widget.patient.patientUuid,
        category: order.category.name,
        label: order.label,
        directions: order.directions,
        frequency: order.frequency,
        orderedBy: _staffId!,
        startedAt: now,
        plannedEndAt: order.durationDays != null ? now.add(Duration(days: order.durationDays!)) : null,
      );
    }
    if (!mounted) return;
    setState(() {
      _pending.clear();
      _saving = false;
    });
    Navigator.pop(context);
  }

  // Basket chip — solid category color, white text, matching the preset
  // chip it came from so the two states read as visibly the same thing.
  Widget _buildPendingChip(_PendingOrder order) {
    final Color color = orderCategoryColors[order.category] ?? AppTheme.deepLogicViolet;
    return InputChip(
      visualDensity: VisualDensity.compact,
      label: Text(order.label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
      avatar: Icon(orderCategoryIcons[order.category], size: 14, color: Colors.white),
      backgroundColor: color,
      deleteIconColor: Colors.white70,
      onPressed: () => _openDetail(order),
      onDeleted: () => _removePending(order),
    );
  }

  Widget _buildChipSection(OrderCategory category, List<String> presets) {
    final Color color = orderCategoryColors[category] ?? AppTheme.deepLogicViolet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              Icon(orderCategoryIcons[category], size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                orderCategoryLabels[category]!,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: presets.map((preset) {
            final bool selected = _pending.any((o) => o.label == preset);
            return ChoiceChip(
              visualDensity: VisualDensity.compact,
              label: Text(
                preset,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                ),
              ),
              selected: selected,
              selectedColor: color,
              backgroundColor: Colors.white,
              side: BorderSide(color: color, width: 1.2),
              showCheckmark: false,
              onSelected: (_) => _addPreset(category, preset),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = "${widget.patient.firstName} ${widget.patient.lastName}";
    return Scaffold(
      appBar: AppBar(
        title: Text("New Orders — $name", style: const TextStyle(fontSize: 15)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Symbols.history), tooltip: "Order history", onPressed: _showHistory),
        ],
        backgroundColor: AppTheme.clinicalWhite,
        elevation: 0,
      ),
      backgroundColor: AppTheme.clinicalWhite,
      body: SafeArea(
        child: Column(
          children: [
            // The "box" — queued orders as chips, plus a place to type
            // anything not covered by a preset. Tap a chip to add detail.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pending.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(spacing: 8, runSpacing: 8, children: _pending.map(_buildPendingChip).toList()),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          onSubmitted: (_) => _addCustom(),
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "Type an order not shown below…",
                            hintStyle: TextStyle(fontSize: 13),
                            isDense: true,
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: _addCustom,
                        style: IconButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in commonOrderPresets.entries) _buildChipSection(entry.key, entry.value),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.clinicalWhite,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _staffId,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: AppTheme.deepCharcoal),
                    decoration: const InputDecoration(labelText: "Ordered by", labelStyle: TextStyle(fontSize: 13)),
                    items: StaffFactory.instance.allStaff.values
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.firstName} ${s.lastName} — ${s.position}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _staffId = val),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_saving || _pending.isEmpty || _staffId == null) ? null : _saveAll,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
                      child: Text(
                        _pending.isEmpty ? "Save Orders" : "Save ${_pending.length} Order${_pending.length == 1 ? '' : 's'}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Per-order detail — how it's carried out and for how long. E.g. the chip
// might be "Exercise"; the directions "Walk around the ward with IV trolley
// until strength returns."
class _OrderDetailSheet extends StatefulWidget {
  final _PendingOrder order;
  const _OrderDetailSheet({required this.order});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  late final TextEditingController _directionsController = TextEditingController(text: widget.order.directions);
  late final TextEditingController _frequencyController = TextEditingController(text: widget.order.frequency ?? '');
  late bool _hasEndDate = widget.order.durationDays != null;
  late final TextEditingController _daysController = TextEditingController(
    text: widget.order.durationDays?.toString() ?? '',
  );

  @override
  void dispose() {
    _directionsController.dispose();
    _frequencyController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _save() {
    widget.order.directions = _directionsController.text.trim().isEmpty
        ? widget.order.label
        : _directionsController.text.trim();
    widget.order.frequency = _frequencyController.text.trim().isEmpty ? null : _frequencyController.text.trim();
    widget.order.durationDays = _hasEndDate ? int.tryParse(_daysController.text.trim()) : null;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.order.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _directionsController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Directions", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _frequencyController,
                decoration: const InputDecoration(labelText: "Frequency (optional)"),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Set an end date"),
                subtitle: Text(_hasEndDate ? "Ends after a fixed number of days" : "Ongoing until discontinued"),
                value: _hasEndDate,
                onChanged: (val) => setState(() => _hasEndDate = val),
              ),
              if (_hasEndDate)
                TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Duration (days)"),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepLogicViolet),
                  child: const Text("Done", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Past orders for this patient — reachable via the history icon, kept
// separate so the composer above stays the fast, low-friction default.
class _OrderHistorySheet extends StatefulWidget {
  final Patient patient;
  const _OrderHistorySheet({required this.patient});

  @override
  State<_OrderHistorySheet> createState() => _OrderHistorySheetState();
}

class _OrderHistorySheetState extends State<_OrderHistorySheet> {
  List<Therapy> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseManager().getCareOrdersForPatient(widget.patient.patientUuid);
    if (mounted) {
      setState(() {
        _orders = rows.map(Therapy.fromJson).toList();
        _loading = false;
      });
    }
  }

  Future<void> _discontinue(Therapy order) async {
    await DatabaseManager().discontinueCareOrder(orderId: order.id);
    await _load();
  }

  Widget _buildOrderTile(Therapy order) {
    final StaffMember? decider = StaffFactory.instance.getStaffMember(id: order.orderedBy);
    return ListTile(
      leading: Icon(order.icon, color: order.isActive ? AppTheme.deepLogicViolet : Colors.grey),
      title: Text(
        order.label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: order.isActive ? null : TextDecoration.lineThrough,
          color: order.isActive ? AppTheme.deepCharcoal : Colors.grey,
        ),
      ),
      subtitle: Text(
        [
          if (order.directions.isNotEmpty) order.directions,
          if (order.frequency != null && order.frequency!.isNotEmpty) order.frequency,
          'Ordered by ${decider != null ? '${decider.firstName} ${decider.lastName}' : 'Unknown'}',
          DateFormat('MMM d, y').format(order.startedAt),
        ].whereType<String>().join(' • '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: order.isActive
          ? TextButton(onPressed: () => _discontinue(order), child: const Text("Discontinue"))
          : null,
      isThreeLine: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text("No care orders recorded yet."))
              : ListView(children: _orders.map(_buildOrderTile).toList()),
    );
  }
}
