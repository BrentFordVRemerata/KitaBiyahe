import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/finance.dart';
import '../core/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

class QuickCheckPage extends StatefulWidget {
  final RiderAppState state;
  final ShiftRecord? editing;
  final VoidCallback onFinished;
  final ValueChanged<bool>? onDirtyChanged;
  const QuickCheckPage({
    super.key,
    required this.state,
    this.editing,
    required this.onFinished,
    this.onDirtyChanged,
  });
  @override
  State<QuickCheckPage> createState() => QuickCheckPageState();
}

class QuickCheckPageState extends State<QuickCheckPage> {
  late final TextEditingController earningsCtrl;
  late final TextEditingController manualFuelCtrl;
  late final TextEditingController distanceCtrl;
  late final TextEditingController efficiencyCtrl;
  late final TextEditingController fuelPriceCtrl;
  late final TextEditingController otherCtrl;
  late final TextEditingController reserveCtrl;
  late final TextEditingController notesCtrl;
  late final FuelUnit entryUnit;
  late final String initialFingerprint;
  bool reportedDirty = false;
  bool confirmingDiscard = false;
  late EarningsMode earningsMode;
  late FuelMethod fuelMethod;
  late EfficiencySource efficiencySource;
  late bool feesConfirmed;
  late DateTime workDate;
  late List<IncomeItem> items;
  late String originalEfficiencyText;
  double? originalEfficiencyKmL;
  bool costsExpanded = false;
  bool saving = false;
  bool showDetailedMath = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.editing?.input;
    final defaults = widget.state.settings;
    entryUnit = defaults.fuelUnit;
    earningsCtrl = TextEditingController(
      text: Peso.editable(initial?.quickEarningsCents),
    );
    manualFuelCtrl = TextEditingController(
      text: Peso.editable(initial?.manualFuelCents),
    );
    distanceCtrl = TextEditingController(
      text: initial?.distanceKm?.toString() ?? '',
    );
    originalEfficiencyKmL = initial == null
        ? defaults.efficiencyKmL
        : initial.efficiencyKmL;
    originalEfficiencyText = originalEfficiencyKmL == null
        ? ''
        : FuelMath.fromKmPerLiter(
            originalEfficiencyKmL!,
            defaults.fuelUnit,
          ).toStringAsFixed(2);
    efficiencyCtrl = TextEditingController(text: originalEfficiencyText);
    fuelPriceCtrl = TextEditingController(
      text: Peso.editable(
        initial == null ? defaults.fuelPriceCents : initial.fuelPriceCents,
      ),
    );
    otherCtrl = TextEditingController(
      text: Peso.editable(initial?.otherCostCents),
    );
    reserveCtrl = TextEditingController(
      text: Peso.editable(
        initial == null
            ? defaults.reservePerKmCents
            : initial.reservePerKmCents,
      ),
    );
    notesCtrl = TextEditingController(text: initial?.notes ?? '');
    earningsMode = initial?.earningsMode ?? EarningsMode.quick;
    fuelMethod = initial?.fuelMethod ?? FuelMethod.unknown;
    efficiencySource = initial?.efficiencySource ?? defaults.efficiencySource;
    feesConfirmed = initial?.afterPlatformFeesConfirmed ?? true;
    workDate = widget.editing?.workDate ?? DateTime.now();
    items = [...?initial?.items];
    costsExpanded =
        widget.editing != null &&
        (initial?.fuelMethod != FuelMethod.unknown ||
            initial?.otherCostCents != null);
    initialFingerprint = fingerprint();
    for (final controller in controllers) {
      controller.addListener(refresh);
    }
  }

  List<TextEditingController> get controllers => [
    earningsCtrl,
    manualFuelCtrl,
    distanceCtrl,
    efficiencyCtrl,
    fuelPriceCtrl,
    otherCtrl,
    reserveCtrl,
    notesCtrl,
  ];

  String fingerprint() => jsonEncode({
    'text': [for (final controller in controllers) controller.text],
    'date': dateText(workDate),
    'mode': earningsMode.name,
    'fuel': fuelMethod.name,
    'efficiencySource': efficiencySource.name,
    'fees': feesConfirmed,
    'items': [for (final item in items) item.toJson()],
  });

  bool get hasUnsavedChanges => fingerprint() != initialFingerprint;

  Future<bool> confirmDiscard({required String action}) async {
    if (saving || confirmingDiscard) return false;
    if (!hasUnsavedChanges) return true;
    confirmingDiscard = true;
    try {
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Discard unsaved entries?'),
              content: Text(
                'These changes have not been saved. Discard them to $action?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep editing'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard changes'),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      confirmingDiscard = false;
    }
  }

  void reportDirty() {
    final dirty = hasUnsavedChanges;
    if (dirty == reportedDirty) return;
    reportedDirty = dirty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDirtyChanged?.call(dirty);
    });
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void refresh([String? text]) => setState(() {});
  String dateText(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double? number(TextEditingController ctrl) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return null;
    final n = double.tryParse(text);
    if (n == null || !n.isFinite) {
      throw const FormatException('Enter a valid decimal number.');
    }
    return n;
  }

  ShiftInput readInput() {
    final efficiencyRaw = number(efficiencyCtrl);
    return ShiftInput(
      earningsMode: earningsMode,
      quickEarningsCents: Peso.parse(earningsCtrl.text),
      items: List.unmodifiable(items),
      afterPlatformFeesConfirmed: feesConfirmed,
      fuelMethod: fuelMethod,
      manualFuelCents: Peso.parse(manualFuelCtrl.text),
      distanceKm: number(distanceCtrl),
      efficiencyKmL: efficiencyCtrl.text == originalEfficiencyText
          ? originalEfficiencyKmL
          : efficiencyRaw == null
          ? null
          : FuelMath.kmPerLiter(efficiencyRaw, entryUnit),
      efficiencySource: efficiencySource,
      fuelPriceCents: Peso.parse(fuelPriceCtrl.text),
      otherCostCents: Peso.parse(otherCtrl.text),
      reservePerKmCents: Peso.parse(reserveCtrl.text),
      hours: widget.editing?.input.hours,
      targetCents: widget.editing?.input.targetCents,
      notes: notesCtrl.text.trim(),
    );
  }

  FinancialSnapshot? preview() {
    try {
      return FinancialEngine.evaluate(readInput());
    } catch (_) {
      return null;
    }
  }

  Future<void> saveShift() async {
    if (saving) return;
    ShiftInput input;
    try {
      input = readInput();
      final result = FinancialEngine.evaluate(input);
      if (result.status == EstimateStatus.invalid) {
        throw FormatException(result.problems.join(' '));
      }
      if (input.earningsCents == null) {
        throw const FormatException(
          'Enter shift earnings first. You can save even if costs are unknown.',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Check entries: $e')));
      return;
    }
    setState(() => saving = true);
    try {
      await widget.state.upsert(input, id: widget.editing?.id, date: workDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Shift saved locally. Export a JSON backup for safekeeping.',
            ),
          ),
        );
        widget.onFinished();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: workDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => workDate = picked);
  }

  Future<void> tryIllustrativeExample() async {
    if (!await confirmDiscard(action: 'load the example figures') || !mounted) {
      return;
    }
    final unit = entryUnit;
    setState(() {
      earningsMode = EarningsMode.quick;
      earningsCtrl.text = '1200.00';
      feesConfirmed = true;
      fuelMethod = FuelMethod.distance;
      distanceCtrl.text = '100';
      originalEfficiencyKmL = 40;
      originalEfficiencyText = FuelMath.fromKmPerLiter(
        40,
        unit,
      ).toStringAsFixed(2);
      efficiencyCtrl.text = originalEfficiencyText;
      fuelPriceCtrl.text = '65.00';
      otherCtrl.text = '80.00';
      reserveCtrl.text = '1.00';
      efficiencySource = EfficiencySource.estimate;
      costsExpanded = true;
      showDetailedMath = true;
    });
  }

  Future<void> switchMode(EarningsMode next) async {
    if (earningsMode == next) return;
    final hasExisting = earningsMode == EarningsMode.quick
        ? earningsCtrl.text.trim().isNotEmpty
        : items.isNotEmpty;
    if (hasExisting) {
      final allowed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Switch earnings entry method?'),
          content: const Text(
            'Quick total and one-by-one entries are NOT added together. Your previous values remain in the form, but only the selected method counts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Switch method'),
            ),
          ],
        ),
      );
      if (allowed != true || !mounted) return;
    }
    setState(() => earningsMode = next);
  }

  Future<void> addIncomeItem() async {
    if (items.length >= FinancialEngine.maxEntries) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum 40 entries per shift. Use Quick total for longer shifts.',
          ),
        ),
      );
      return;
    }
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    var source = 'Grab';
    var kind = IncomeKind.jobs;
    try {
      final entry = await showModalBottomSheet<IncomeItem>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, localSet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add earnings',
                      style: Theme.of(ctx).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 9),
                    const InfoBanner(
                      text:
                          'Enter the amount after applicable platform fees. Add tips and bonuses only if they are NOT already part of the platform total.',
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: source,
                      isExpanded: true,
                      isDense: false,
                      itemHeight: null,
                      decoration: const InputDecoration(
                        labelText: 'Where did it come from?',
                      ),
                      items:
                          [
                                'Grab',
                                'MOVE IT',
                                'Angkas',
                                'JoyRide',
                                'Other app',
                                'Direct / cash booking',
                              ]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (v) => localSet(() => source = v ?? source),
                    ),
                    const SizedBox(height: 13),
                    DropdownButtonFormField<IncomeKind>(
                      initialValue: kind,
                      isExpanded: true,
                      isDense: false,
                      itemHeight: null,
                      decoration: const InputDecoration(
                        labelText: 'What type of income?',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: IncomeKind.jobs,
                          child: Text('Booking earnings'),
                        ),
                        DropdownMenuItem(
                          value: IncomeKind.tip,
                          child: Text('Extra tip not yet counted'),
                        ),
                        DropdownMenuItem(
                          value: IncomeKind.bonus,
                          child: Text('Extra incentive/bonus'),
                        ),
                        DropdownMenuItem(
                          value: IncomeKind.adjustment,
                          child: Text('Adjustment / correction (+/−)'),
                        ),
                      ],
                      onChanged: (v) => localSet(() => kind = v ?? kind),
                    ),
                    const SizedBox(height: 13),
                    TextEntry(
                      controller: amountCtrl,
                      label: 'Amount after any fees',
                      suffix: '₱',
                      hint: 'e.g. 150.00',
                      allowNegative: kind == IncomeKind.adjustment,
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: refCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Optional transaction/reference ID',
                        hintText: 'Helps prevent duplicate entries',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          try {
                            final amount = Peso.parse(
                              amountCtrl.text,
                              allowNegative: kind == IncomeKind.adjustment,
                            );
                            if (amount == null) {
                              throw const FormatException(
                                'Please enter an amount.',
                              );
                            }
                            final ref = refCtrl.text.trim();
                            if (ref.isNotEmpty &&
                                items.any(
                                  (v) =>
                                      v.source == source &&
                                      v.reference.toLowerCase() ==
                                          ref.toLowerCase(),
                                )) {
                              throw const FormatException(
                                'This source and transaction reference are already added.',
                              );
                            }
                            Navigator.pop(
                              ctx,
                              IncomeItem(
                                id: '${DateTime.now().microsecondsSinceEpoch}',
                                source: source,
                                kind: kind,
                                amountCents: amount,
                                reference: ref,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(
                              ctx,
                            ).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add to shift total'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      if (entry != null && mounted) setState(() => items.add(entry));
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      amountCtrl.dispose();
      refCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    reportDirty();
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1050;
    final previewResult = preview();
    final useTaglish = widget.state.settings.useTaglish;
    final content = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SectionTitle(
              eyebrow: 'Your shift · Local-first',
              title: widget.editing == null ? 'QuickCheck' : 'Edit saved shift',
              subtitle: 'Simple earnings, honest costs, walang hulaan.',
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Try example figures',
            onPressed: tryIllustrativeExample,
            icon: const Icon(Icons.science_outlined),
          ),
        ],
      ),
      const SizedBox(height: 17),
      _resultCard(context, previewResult),
      const SizedBox(height: 20),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text(
                  '01  ·  YOUR EARNINGS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                TextButton.icon(
                  onPressed: chooseDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(dateText(workDate)),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              useTaglish
                  ? 'Magkano ang kinita mo sa shift?'
                  : 'How much did you earn this shift?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            const Text(
              'Choose ONE way to record it. Do not add the same fare twice.',
              style: TextStyle(color: KitaColors.muted),
            ),
            const SizedBox(height: 18),
            SegmentedButton<EarningsMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: EarningsMode.quick,
                  label: Text('Quick total'),
                  icon: Icon(Icons.flash_on_outlined),
                ),
                ButtonSegment(
                  value: EarningsMode.itemized,
                  label: Text('One by one'),
                  icon: Icon(Icons.list_alt_outlined),
                ),
              ],
              selected: {earningsMode},
              onSelectionChanged: (next) => switchMode(next.first),
            ),
            const SizedBox(height: 20),
            if (earningsMode == EarningsMode.quick)
              TextEntry(
                controller: earningsCtrl,
                label: 'Earnings AFTER platform fees',
                suffix: '₱',
                hint: 'e.g. 1200.00',
                help:
                    'Copy the correct total from your rider platform. Check whether tips and bonuses are already included.',
                onHelp: () => showPlainHelp(
                  context,
                  'Where do I find my earnings?',
                  'Open your rider app → completed jobs/earnings statement. Look for the amount AFTER applicable platform fees. Some apps show tips, incentives or adjustments separately. Include each earning only once. Never assume wallet balance means earnings.',
                ),
                onChanged: refresh,
              )
            else
              _itemizedEditor(context),
            const SizedBox(height: 14),
            CheckboxListTile(
              value: feesConfirmed,
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Platform fees already accounted for'),
              subtitle: const Text(
                'If unsure, leave unchecked; this is a partial record.',
              ),
              onChanged: (v) => setState(() => feesConfirmed = v ?? false),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: saving ? null : saveShift,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  widget.editing == null
                      ? 'Save this shift (even if incomplete)'
                      : 'Update this shift',
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => costsExpanded = !costsExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: KitaColors.mint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_gas_station_outlined,
                        color: KitaColors.forest,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '02  ·  GASOLINE & COSTS',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Estimate expenses or skip what you do not know',
                            style: TextStyle(
                              fontSize: 12,
                              color: KitaColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      costsExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),
            if (costsExpanded) ...[
              const SizedBox(height: 19),
              const Divider(),
              const SizedBox(height: 15),
              _fuelEntry(context),
              const SizedBox(height: 20),
              _otherEntry(context),
              const SizedBox(height: 18),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Optional notes',
                  hintText: 'e.g. Rainy day, two platforms',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving ? null : saveShift,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    widget.editing == null ? 'Save this shift' : 'Save changes',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: KitaColors.muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Only saved shifts are kept. Unsaved entries are lost when the app closes. Export a backup in Settings.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      const SizedBox(height: 36),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 950 : 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          ),
        ),
      ),
    );
  }

  Widget _itemizedEditor(BuildContext context) {
    final cents = items.fold<int>(0, (sum, item) => sum + item.amountCents);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoBanner(
          text:
              'Add bookings, bonuses, or tips not already included in another total. The app sums ONLY these entries; Quick total is ignored.',
        ),
        const SizedBox(height: 12),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: KitaColors.canvas,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_outlined,
                        color: KitaColors.forest,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.source} · ${item.kind.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.reference.isNotEmpty)
                              Text(
                                'Ref ${item.reference}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove entry',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => items.remove(item)),
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      Peso.compact(item.amountCents),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Text(
              'Itemized total  ${Peso.compact(items.isEmpty ? null : cents)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            OutlinedButton.icon(
              onPressed: addIncomeItem,
              icon: const Icon(Icons.add),
              label: const Text('Add entry'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fuelEntry(BuildContext context) {
    final unit = entryUnit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How do you know your fuel cost?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Not sure yet'),
              avatar: const Icon(Icons.help_outline, size: 17),
              selected: fuelMethod == FuelMethod.unknown,
              onSelected: (_) =>
                  setState(() => fuelMethod = FuelMethod.unknown),
            ),
            ChoiceChip(
              label: const Text('Fuel amount'),
              avatar: const Icon(Icons.payments_outlined, size: 17),
              selected: fuelMethod == FuelMethod.manual,
              onSelected: (_) => setState(() => fuelMethod = FuelMethod.manual),
            ),
            ChoiceChip(
              label: const Text('From distance'),
              avatar: const Icon(Icons.route_outlined, size: 17),
              selected: fuelMethod == FuelMethod.distance,
              onSelected: (_) =>
                  setState(() => fuelMethod = FuelMethod.distance),
            ),
          ],
        ),
        const SizedBox(height: 13),
        if (fuelMethod == FuelMethod.unknown)
          const InfoBanner(
            text:
                'Hindi mo pa alam? Okay lang. Save your earnings now and complete gasoline costs later.',
          ),
        if (fuelMethod == FuelMethod.manual)
          TextEntry(
            controller: manualFuelCtrl,
            label: 'Estimated value of fuel USED during work',
            suffix: '₱',
            hint: 'e.g. 150.00',
            onChanged: refresh,
            help:
                'Not the amount of gasoline you purchased at the pump, unless it was all used for this shift.',
            onHelp: () => showPlainHelp(
              context,
              'Fuel consumed ≠ fuel purchased',
              'If you refilled ₱300 but some gasoline remains, ₱300 is not necessarily your work fuel cost. Use your estimate of gasoline consumed. If unsure, leave this unknown or estimate using work distance, efficiency and fuel price.',
            ),
          ),
        if (fuelMethod == FuelMethod.distance) ...[
          TextEntry(
            controller: distanceCtrl,
            label: 'Work-related distance',
            suffix: 'km',
            hint: 'e.g. 100',
            help:
                'Odometer/trip start → end; exclude private travel if possible.',
            onChanged: refresh,
            onHelp: () => showPlainHelp(
              context,
              'Where to get work kilometers',
              'Before work, note your odometer or reset Trip A. After the shift, subtract the starting reading from the ending reading. Include work-related travel to pickups and repositioning, not just completed-booking kilometers. If personal travel is mixed in, note the uncertainty.',
            ),
          ),
          const SizedBox(height: 12),
          TextEntry(
            controller: efficiencyCtrl,
            label: 'Motorcycle fuel efficiency',
            suffix: unit.label,
            hint: 'Your motorcycle value',
            onChanged: refresh,
            help:
                'Settings → My Motorcycle lets you measure km/L from two complete refills. Unit is converted automatically.',
            onHelp: () => showPlainHelp(
              context,
              'What is ${unit.label}?',
              'Fuel efficiency is how far your motorcycle goes per liter. Check a manual or record two consistent full refills with odometer readings. Use Settings → Measure my km/L for a guided calculator. There is no universal motorcycle km/L.',
            ),
          ),
          const SizedBox(height: 12),
          TextEntry(
            controller: fuelPriceCtrl,
            label: 'Gasoline price per liter',
            suffix: '₱/L',
            hint: 'e.g. 65.00',
            help: 'Use the price at the station from your receipt or pump.',
            onChanged: refresh,
          ),
        ],
        if (fuelMethod != FuelMethod.distance) ...[
          const SizedBox(height: 12),
          TextEntry(
            controller: distanceCtrl,
            label: 'Work km (optional)',
            suffix: 'km',
            hint: 'Needed only for a per-km maintenance allowance',
            onChanged: refresh,
          ),
        ],
      ],
    );
  }

  Widget _otherEntry(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Other costs and planned allowance',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 13),
      TextEntry(
        controller: otherCtrl,
        label: 'Other expenses actually spent on this shift',
        suffix: '₱',
        hint: 'e.g. 80.00',
        help:
            'Parking, toll, data or other work expense if paid. Leave blank when unknown.',
        onChanged: refresh,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => setState(() => otherCtrl.text = '0.00'),
          child: const Text('No other expenses — enter ₱0'),
        ),
      ),
      const SizedBox(height: 9),
      TextEntry(
        controller: reserveCtrl,
        label: 'Planned maintenance allowance per work km',
        suffix: '₱/km',
        hint: 'Optional; e.g. 1.00',
        help:
            'Planned saving for tires/service — NOT cash spent today. It is separate from the cash remainder.',
        onChanged: refresh,
        onHelp: () => showPlainHelp(
          context,
          'What is a maintenance allowance?',
          'This is money you choose to set aside for future motorcycle repairs or wear. It is NOT a receipt or actual spending today. Enter 0 if you do not want to calculate it. If you choose a rate per km, work distance is needed.',
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => setState(() => reserveCtrl.text = '0.00'),
          child: const Text('Exclude maintenance allowance — ₱0'),
        ),
      ),
    ],
  );

  Widget _resultCard(BuildContext context, FinancialSnapshot? result) {
    final invalid = result == null || result.status == EstimateStatus.invalid;
    final title = switch (result?.status) {
      EstimateStatus.supported => 'Estimated after listed costs + allowance',
      EstimateStatus.rough => 'Estimated after known costs',
      EstimateStatus.partial => 'Earnings recorded · costs incomplete',
      EstimateStatus.empty => 'Start with your earnings',
      _ => 'Check your entries',
    };
    final shown = result?.afterReserveCents ?? result?.cashRemainderCents;
    final isEstimate = shown != null && !invalid;
    final duration =
        widget.state.settings.reduceMotion ||
            MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 320);
    return SoftCard(
      color: KitaColors.forest,
      outlined: false,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'YOUR SHIFT · LIVE PREVIEW',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFD6ECDF),
                  letterSpacing: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B6A53),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  isEstimate ? 'Estimated' : 'Incomplete',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD6ECDF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: duration,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              key: ValueKey(shown),
              isEstimate ? Peso.compact(shown) : '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                letterSpacing: -1.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            !isEstimate
                ? (result?.earningsCents == null
                      ? 'Enter your earnings below. No values are invented.'
                      : 'Recorded earnings: ${Peso.compact(result!.earningsCents)}. Complete relevant costs for an estimate.')
                : 'An estimate, NOT verified profit or money in your wallet.',
            style: const TextStyle(
              color: Color(0xFFD1E8DB),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (invalid && result?.problems.isNotEmpty == true) ...[
            const SizedBox(height: 9),
            Text(
              result!.problems.first,
              style: const TextStyle(color: Color(0xFFFFCDBB), fontSize: 12),
            ),
          ],
          if (isEstimate) ...[
            const SizedBox(height: 15),
            const Divider(color: Color(0xFF477965)),
            const SizedBox(height: 13),
            _resultLine('Recorded earnings', result.earningsCents),
            _resultLine(
              'Estimated gasoline used',
              result.fuelCents,
              negative: true,
            ),
            _resultLine(
              'Other listed expenses',
              result.otherCents,
              negative: true,
            ),
            if (result.reserveCents != null)
              _resultLine(
                'Planned maintenance allowance',
                result.reserveCents,
                negative: true,
              ),
            if (result.cashRemainderCents != null &&
                result.reserveCents != null) ...[
              const Divider(color: Color(0xFF477965)),
              _resultLine(
                'Before savings allowance',
                result.cashRemainderCents,
              ),
            ],
            const SizedBox(height: 8),
            _costMeter(result, duration),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                setState(() => showDetailedMath = !showDetailedMath),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: Icon(
              showDetailedMath ? Icons.expand_less : Icons.expand_more,
            ),
            label: Text(
              showDetailedMath ? 'Hide explanation' : 'What is included?',
            ),
          ),
          if (showDetailedMath) ...[
            const SizedBox(height: 6),
            Text(
              result == null
                  ? 'Fix invalid numbers first.'
                  : result.missing.isEmpty
                  ? 'All explicitly selected categories have values.'
                  : 'Still missing or excluded: ${result.missing.join('; ')}.',
              style: const TextStyle(
                color: Color(0xFFD6ECDF),
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Formula: earnings − estimated work fuel − entered other expenses = remainder before reserve. Minus your planned maintenance allowance only when specified.',
              style: TextStyle(
                color: Color(0xFFD6ECDF),
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultLine(String label, int? cents, {bool negative = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFFDEEDE4)),
              ),
            ),
            Text(
              cents == null
                  ? '—'
                  : '${negative ? '−' : ''}${Peso.compact(cents)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _costMeter(FinancialSnapshot result, Duration duration) {
    final total = result.earningsCents ?? 0;
    final cost =
        (result.fuelCents ?? 0) +
        (result.otherCents ?? 0) +
        (result.reserveCents ?? 0);
    if (total <= 0) return const SizedBox.shrink();
    final fraction = (cost / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 9,
            width: double.infinity,
            color: const Color(0xFF608C78),
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              duration: duration,
              tween: Tween<double>(begin: 0, end: fraction),
              builder: (ctx, value, child) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(color: const Color(0xFFFFC17A)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Listed costs + allowance: ${(fraction * 100).toStringAsFixed(0)}% of recorded earnings (capped at 100% on bar)',
          style: const TextStyle(color: Color(0xFFD6ECDF), fontSize: 10),
        ),
      ],
    );
  }
}
