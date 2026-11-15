import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/finance.dart';
import 'theme.dart';
import 'widgets.dart';

class HistoryPage extends StatefulWidget {
  final RiderAppState state;
  final ValueChanged<ShiftRecord> onEdit;
  final VoidCallback onNew;
  const HistoryPage({
    super.key,
    required this.state,
    required this.onEdit,
    required this.onNew,
  });
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String filter = 'All';
  String dateLabel(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final records = widget.state.records.where((record) {
      if (filter == '7 days') {
        return !record.workDate.isBefore(now.subtract(const Duration(days: 7)));
      }
      if (filter == 'This month') {
        return record.workDate.year == now.year &&
            record.workDate.month == now.month;
      }
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    var completed = 0;
    int included = 0;
    for (final record in records) {
      final result = FinancialEngine.evaluate(record.input);
      if (result.afterReserveCents != null) {
        completed++;
        included += result.afterReserveCents!;
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            eyebrow: 'Your records',
            title: 'Shift history',
            subtitle:
                'Review past estimates. Incomplete shifts remain incomplete.',
          ),
          const SizedBox(height: 22),
          SoftCard(
            color: KitaColors.mint,
            outlined: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'After-reserve total from $completed completed shift(s)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Peso.compact(included),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${records.length - completed} shift(s) are excluded because their estimates are incomplete. Not actual cash held.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            children: ['All', '7 days', 'This month']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: filter == v,
                    onSelected: (_) => setState(() => filter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 34,
                    color: KitaColors.forest,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Wala pang record dito',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Save a shift in QuickCheck, even if some expenses are unknown.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: widget.onNew,
                    child: const Text('New shift'),
                  ),
                ],
              ),
            ),
          for (final record in records) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _recordTile(context, record),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recordTile(BuildContext context, ShiftRecord record) {
    final result = FinancialEngine.evaluate(record.input);
    final isComplete = result.afterReserveCents != null;
    final amount =
        result.afterReserveCents ??
        result.cashRemainderCents ??
        result.earningsCents;
    return SoftCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: KitaColors.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: KitaColors.forest,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel(record.workDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      isComplete
                          ? 'After listed costs + allowance'
                          : 'Incomplete estimate · edit to finish',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                Peso.compact(amount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 5,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => widget.onEdit(record),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final answer = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete this shift?'),
                      content: const Text(
                        'This action removes the saved record. Export a backup first if you want to keep it.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (answer == true) {
                    try {
                      await widget.state.remove(record.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not delete: $e')),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
