import 'package:flutter/material.dart';
import '../core/finance.dart';
import 'theme.dart';
import 'widgets.dart';

void showQuickGuide(BuildContext context, {bool reduceMotion = false}) {
  final sample = FinancialEngine.evaluate(
    const ShiftInput(
      quickEarningsCents: 120000,
      fuelMethod: FuelMethod.distance,
      distanceKm: 100,
      efficiencyKmL: 40,
      fuelPriceCents: 6500,
      otherCostCents: 8000,
      reservePerKmCents: 100,
    ),
  );
  final phases =
      <
        ({
          IconData icon,
          String heading,
          String description,
          String label,
          int? cents,
        })
      >[
        (
          icon: Icons.payments_outlined,
          heading: '1. Ilagay ang kinita',
          description:
              'Copy earnings already AFTER platform fees from your rider app. If you prefer, add bookings, tips and bonuses one by one. Avoid adding money already included in the total.',
          label: 'Recorded work earnings',
          cents: sample.earningsCents,
        ),
        (
          icon: Icons.local_gas_station_outlined,
          heading: '2. Alamin ang gasolina',
          description:
              'Choose what you know: estimated fuel consumed, distance + km/L + fuel price, or “Hindi ko pa alam.” A ₱300 refill is a PURCHASE, not necessarily ₱300 used today.',
          label: 'Estimated fuel used',
          cents: sample.fuelCents,
        ),
        (
          icon: Icons.receipt_long_outlined,
          heading: '3. Ilagay ang ibang gastos',
          description:
              'Add other shift expenses when known. Explicit ₱0 means none; a blank means unknown. For this sample we entered ₱80, leaving the amount shown before reserving maintenance money.',
          label: 'After listed cash costs',
          cents: sample.cashRemainderCents,
        ),
        (
          icon: Icons.check_circle_outline,
          heading: '4. Intindihin ang natira',
          description:
              'This sample also sets aside ₱100 for future vehicle maintenance. That is a PLANNED allowance, not necessarily cash spent today. The final result is only an estimate after included costs.',
          label: 'Estimated remainder after allowance',
          cents: sample.afterReserveCents,
        ),
      ];
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: KitaColors.canvas,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        // The state for this bottom sheet lives in an enclosing builder widget below.
        return _GuideExperience(phases: phases, reduceMotion: reduceMotion);
      },
    ),
  );
}

class _GuideExperience extends StatefulWidget {
  final List<
    ({
      IconData icon,
      String heading,
      String description,
      String label,
      int? cents,
    })
  >
  phases;
  final bool reduceMotion;
  const _GuideExperience({required this.phases, required this.reduceMotion});

  @override
  State<_GuideExperience> createState() => _GuideExperienceState();
}

class _GuideExperienceState extends State<_GuideExperience> {
  int step = 0;
  @override
  Widget build(BuildContext context) {
    final phase = widget.phases[step];
    final reduced =
        widget.reduceMotion || MediaQuery.of(context).disableAnimations;
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 330);
    return FractionallySizedBox(
      heightFactor: .76,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                const Text(
                  'PAANO GAMITIN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: KitaColors.muted,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Skip guide'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(
                widget.phases.length,
                (i) => Expanded(
                  child: AnimatedContainer(
                    duration: duration,
                    height: 5,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: i <= step ? KitaColors.forest : KitaColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: reduced ? Offset.zero : const Offset(.04, .05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: SingleChildScrollView(
                  key: ValueKey(step),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: KitaColors.mint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          phase.icon,
                          color: KitaColors.forest,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        phase.heading,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        phase.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      SoftCard(
                        color: KitaColors.forest,
                        outlined: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phase.label,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                Peso.compact(phase.cents),
                                style: const TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'EXAMPLE ONLY · Not typical rider earnings',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: .3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                if (step > 0)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => step--),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Back'),
                  ),
                FilledButton.icon(
                  onPressed: step == widget.phases.length - 1
                      ? () => Navigator.pop(context)
                      : () => setState(() => step++),
                  icon: Icon(
                    step == widget.phases.length - 1
                        ? Icons.check
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    step == widget.phases.length - 1
                        ? 'Start QuickCheck'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
