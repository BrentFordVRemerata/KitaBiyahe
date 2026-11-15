/// All money is stored as integer centavos, not floating-point pesos.
/// Null means unknown; zero is deliberately entered.
class Peso {
  static final RegExp _pattern = RegExp(
    r'^-?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d{1,2})?$',
  );

  static int? parse(String? raw, {bool allowNegative = false}) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    if (!_pattern.hasMatch(text) || (!allowNegative && text.startsWith('-'))) {
      throw const FormatException(
        'Enter pesos with at most two decimal places.',
      );
    }
    final negative = text.startsWith('-');
    final unsigned = negative ? text.substring(1) : text;
    final parts = unsigned.split('.');
    final wholeText = parts.first.replaceAll(',', '');
    final significantWhole = wholeText.replaceFirst(RegExp(r'^0+'), '');
    if (significantWhole.length > 8) {
      throw const FormatException('Amount is unusually high; check the entry.');
    }
    final whole = int.parse(wholeText);
    final fraction = parts.length == 2
        ? int.parse(parts[1].padRight(2, '0'))
        : 0;
    final cents = (whole * 100 + fraction) * (negative ? -1 : 1);
    if (cents < -1000000000 || cents > 1000000000) {
      throw const FormatException('Amount is unusually high; check the entry.');
    }
    return cents;
  }

  static String compact(int? cents) {
    if (cents == null) return '—';
    final absVal = BigInt.from(cents).abs();
    final whole = (absVal ~/ BigInt.from(100)).toString();
    final grouped = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    final dec = (absVal % BigInt.from(100)).toString().padLeft(2, '0');
    return '${cents < 0 ? '−' : ''}₱$grouped.$dec';
  }

  static String editable(int? cents) => cents == null
      ? ''
      : '${cents < 0 ? '-' : ''}${BigInt.from(cents).abs() ~/ BigInt.from(100)}.${(BigInt.from(cents).abs() % BigInt.from(100)).toString().padLeft(2, '0')}';
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int) {
    throw FormatException('$key must be an integer centavo value.');
  }
  return value;
}

double? _optionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite) {
    throw FormatException('$key must be a finite number.');
  }
  return value.toDouble();
}

String _optionalString(Map<String, dynamic> json, String key, String fallback) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! String) throw FormatException('$key must be text.');
  return value;
}

bool _optionalBool(Map<String, dynamic> json, String key, bool fallback) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! bool) throw FormatException('$key must be true or false.');
  return value;
}

String? _optionalEnumName(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key must be text.');
  return value;
}

List<IncomeItem> _incomeItems(Map<String, dynamic> json) {
  final value = json['items'];
  if (value == null) return const [];
  if (value is! List) throw const FormatException('items must be a list.');
  return value.map((item) {
    if (item is! Map) {
      throw const FormatException('Each income item must be an object.');
    }
    return IncomeItem.fromJson(Map<String, dynamic>.from(item));
  }).toList();
}

enum FuelMethod { unknown, manual, distance }

enum EarningsMode { quick, itemized }

enum FuelUnit { kmPerLiter, mpgUs, mpgUk, litersPer100Km }

enum EfficiencySource { unknown, measured, manufacturer, estimate }

enum IncomeKind { jobs, tip, bonus, adjustment }

enum EstimateStatus { empty, partial, rough, supported, invalid }

extension FuelUnitLabel on FuelUnit {
  String get label => switch (this) {
    FuelUnit.kmPerLiter => 'km/L',
    FuelUnit.mpgUs => 'MPG (US)',
    FuelUnit.mpgUk => 'MPG (UK)',
    FuelUnit.litersPer100Km => 'L/100 km',
  };
}

class FuelMath {
  static const usMpgPerKml = 2.352145833333333;
  static const ukMpgPerKml = 2.824809363318222;

  static double kmPerLiter(double value, FuelUnit unit) {
    if (!value.isFinite || value <= 0) {
      throw const FormatException('Fuel efficiency must be positive.');
    }
    final result = switch (unit) {
      FuelUnit.kmPerLiter => value,
      FuelUnit.mpgUs => value / usMpgPerKml,
      FuelUnit.mpgUk => value / ukMpgPerKml,
      FuelUnit.litersPer100Km => 100 / value,
    };
    if (!result.isFinite || result <= 0) {
      throw const FormatException(
        'Fuel efficiency is outside the supported range.',
      );
    }
    return result;
  }

  static double fromKmPerLiter(double kml, FuelUnit unit) {
    if (!kml.isFinite || kml <= 0) {
      throw const FormatException('Fuel efficiency must be positive.');
    }
    final result = switch (unit) {
      FuelUnit.kmPerLiter => kml,
      FuelUnit.mpgUs => kml * usMpgPerKml,
      FuelUnit.mpgUk => kml * ukMpgPerKml,
      FuelUnit.litersPer100Km => 100 / kml,
    };
    if (!result.isFinite || result <= 0) {
      throw const FormatException(
        'Fuel efficiency is outside the supported range.',
      );
    }
    return result;
  }

  static double fromTwoFullRefills({
    required double firstOdometer,
    required double secondOdometer,
    required double secondRefillLiters,
  }) {
    if (!firstOdometer.isFinite ||
        !secondOdometer.isFinite ||
        !secondRefillLiters.isFinite ||
        firstOdometer < 0 ||
        secondOdometer <= firstOdometer ||
        secondRefillLiters <= 0) {
      throw const FormatException(
        'Use consecutive complete refills with increasing odometer readings and positive liters.',
      );
    }
    final kml = (secondOdometer - firstOdometer) / secondRefillLiters;
    if (!kml.isFinite || kml > 1000) {
      throw const FormatException(
        'Check odometer or liters: unusually high result.',
      );
    }
    return kml;
  }
}

class IncomeItem {
  final String id;
  final String source;
  final IncomeKind kind;
  final int amountCents;
  final String reference;
  const IncomeItem({
    required this.id,
    required this.source,
    required this.kind,
    required this.amountCents,
    this.reference = '',
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'source': source,
    'kind': kind.name,
    'amountCents': amountCents,
    'reference': reference,
  };

  factory IncomeItem.fromJson(Map<String, dynamic> json) => IncomeItem(
    id: _optionalString(json, 'id', ''),
    source: _optionalString(json, 'source', 'Other app'),
    kind: IncomeKind.values.firstWhere(
      (k) => k.name == _optionalEnumName(json, 'kind'),
      orElse: () => IncomeKind.jobs,
    ),
    amountCents:
        _optionalInt(json, 'amountCents') ??
        (throw const FormatException('amountCents is required.')),
    reference: _optionalString(json, 'reference', ''),
  );
}

class RiderSettings {
  final FuelUnit fuelUnit;
  final double? efficiencyKmL;
  final EfficiencySource efficiencySource;
  final int? fuelPriceCents;
  final int? reservePerKmCents;
  final bool reduceMotion;
  final bool useTaglish;
  const RiderSettings({
    this.fuelUnit = FuelUnit.kmPerLiter,
    this.efficiencyKmL,
    this.efficiencySource = EfficiencySource.unknown,
    this.fuelPriceCents,
    this.reservePerKmCents,
    this.reduceMotion = false,
    this.useTaglish = true,
  });

  RiderSettings copyWith({
    FuelUnit? fuelUnit,
    double? efficiencyKmL,
    bool clearEfficiency = false,
    EfficiencySource? efficiencySource,
    int? fuelPriceCents,
    bool clearFuelPrice = false,
    int? reservePerKmCents,
    bool clearReserve = false,
    bool? reduceMotion,
    bool? useTaglish,
  }) => RiderSettings(
    fuelUnit: fuelUnit ?? this.fuelUnit,
    efficiencyKmL: clearEfficiency
        ? null
        : (efficiencyKmL ?? this.efficiencyKmL),
    efficiencySource: efficiencySource ?? this.efficiencySource,
    fuelPriceCents: clearFuelPrice
        ? null
        : (fuelPriceCents ?? this.fuelPriceCents),
    reservePerKmCents: clearReserve
        ? null
        : (reservePerKmCents ?? this.reservePerKmCents),
    reduceMotion: reduceMotion ?? this.reduceMotion,
    useTaglish: useTaglish ?? this.useTaglish,
  );

  Map<String, Object?> toJson() => {
    'fuelUnit': fuelUnit.name,
    'efficiencyKmL': efficiencyKmL,
    'efficiencySource': efficiencySource.name,
    'fuelPriceCents': fuelPriceCents,
    'reservePerKmCents': reservePerKmCents,
    'reduceMotion': reduceMotion,
    'useTaglish': useTaglish,
  };

  factory RiderSettings.fromJson(Map<String, dynamic> json) {
    final efficiency = _optionalDouble(json, 'efficiencyKmL');
    if (efficiency != null && (efficiency <= 0 || efficiency > 1000)) {
      throw const FormatException(
        'efficiencyKmL is outside the supported range.',
      );
    }
    final fuelPrice = _optionalInt(json, 'fuelPriceCents');
    final reserve = _optionalInt(json, 'reservePerKmCents');
    for (final value in [fuelPrice, reserve]) {
      if (value != null && (value < 0 || value > 1000000000)) {
        throw const FormatException(
          'Settings money must be a valid non-negative centavo amount.',
        );
      }
    }
    return RiderSettings(
      fuelUnit: FuelUnit.values.firstWhere(
        (v) => v.name == _optionalEnumName(json, 'fuelUnit'),
        orElse: () => FuelUnit.kmPerLiter,
      ),
      efficiencyKmL: efficiency,
      efficiencySource: EfficiencySource.values.firstWhere(
        (v) => v.name == _optionalEnumName(json, 'efficiencySource'),
        orElse: () => EfficiencySource.unknown,
      ),
      fuelPriceCents: fuelPrice,
      reservePerKmCents: reserve,
      reduceMotion: _optionalBool(json, 'reduceMotion', false),
      useTaglish: _optionalBool(json, 'useTaglish', true),
    );
  }
}

class ShiftInput {
  final EarningsMode earningsMode;
  final int? quickEarningsCents;
  final List<IncomeItem> items;
  final bool afterPlatformFeesConfirmed;
  final FuelMethod fuelMethod;
  final int? manualFuelCents;
  final double? distanceKm;
  final double? efficiencyKmL;
  final EfficiencySource efficiencySource;
  final int? fuelPriceCents;
  final int? otherCostCents;
  final int? reservePerKmCents;
  final double? hours;
  final int? targetCents;
  final String notes;
  const ShiftInput({
    this.earningsMode = EarningsMode.quick,
    this.quickEarningsCents,
    this.items = const [],
    this.afterPlatformFeesConfirmed = true,
    this.fuelMethod = FuelMethod.unknown,
    this.manualFuelCents,
    this.distanceKm,
    this.efficiencyKmL,
    this.efficiencySource = EfficiencySource.unknown,
    this.fuelPriceCents,
    this.otherCostCents,
    this.reservePerKmCents,
    this.hours,
    this.targetCents,
    this.notes = '',
  });

  int? get earningsCents {
    if (earningsMode == EarningsMode.quick) return quickEarningsCents;
    if (items.isEmpty) return null;
    final total = items.fold<BigInt>(
      BigInt.zero,
      (sum, item) => sum + BigInt.from(item.amountCents),
    );
    final maxSupported = BigInt.from(1000000001);
    if (total > maxSupported) return 1000000001;
    if (total < -maxSupported) return -1000000001;
    return total.toInt();
  }

  Map<String, Object?> toJson() => {
    'earningsMode': earningsMode.name,
    'quickEarningsCents': quickEarningsCents,
    'items': items.map((e) => e.toJson()).toList(),
    'afterPlatformFeesConfirmed': afterPlatformFeesConfirmed,
    'fuelMethod': fuelMethod.name,
    'manualFuelCents': manualFuelCents,
    'distanceKm': distanceKm,
    'efficiencyKmL': efficiencyKmL,
    'efficiencySource': efficiencySource.name,
    'fuelPriceCents': fuelPriceCents,
    'otherCostCents': otherCostCents,
    'reservePerKmCents': reservePerKmCents,
    'hours': hours,
    'targetCents': targetCents,
    'notes': notes,
  };

  factory ShiftInput.fromJson(Map<String, dynamic> json) => ShiftInput(
    earningsMode: EarningsMode.values.firstWhere(
      (v) => v.name == _optionalEnumName(json, 'earningsMode'),
      orElse: () => EarningsMode.quick,
    ),
    quickEarningsCents: _optionalInt(json, 'quickEarningsCents'),
    items: _incomeItems(json),
    afterPlatformFeesConfirmed: _optionalBool(
      json,
      'afterPlatformFeesConfirmed',
      true,
    ),
    fuelMethod: FuelMethod.values.firstWhere(
      (v) => v.name == _optionalEnumName(json, 'fuelMethod'),
      orElse: () => FuelMethod.unknown,
    ),
    manualFuelCents: _optionalInt(json, 'manualFuelCents'),
    distanceKm: _optionalDouble(json, 'distanceKm'),
    efficiencyKmL: _optionalDouble(json, 'efficiencyKmL'),
    efficiencySource: EfficiencySource.values.firstWhere(
      (v) => v.name == _optionalEnumName(json, 'efficiencySource'),
      orElse: () => EfficiencySource.unknown,
    ),
    fuelPriceCents: _optionalInt(json, 'fuelPriceCents'),
    otherCostCents: _optionalInt(json, 'otherCostCents'),
    reservePerKmCents: _optionalInt(json, 'reservePerKmCents'),
    hours: _optionalDouble(json, 'hours'),
    targetCents: _optionalInt(json, 'targetCents'),
    notes: _optionalString(json, 'notes', ''),
  );
}

class FinancialSnapshot {
  final EstimateStatus status;
  final int? earningsCents;
  final int? fuelCents;
  final int? otherCents;
  final int? reserveCents;
  final int? cashRemainderCents;
  final int? afterReserveCents;
  final List<String> missing;
  final List<String> problems;
  const FinancialSnapshot({
    required this.status,
    this.earningsCents,
    this.fuelCents,
    this.otherCents,
    this.reserveCents,
    this.cashRemainderCents,
    this.afterReserveCents,
    this.missing = const [],
    this.problems = const [],
  });
}

class FinancialEngine {
  static const maxEntries = 40;

  static FinancialSnapshot evaluate(ShiftInput input) {
    final problems = <String>[];
    final missing = <String>[];
    final earnings = input.earningsCents;
    if (input.earningsMode == EarningsMode.itemized) {
      if (input.items.length > maxEntries) {
        problems.add('Limit of 40 earning entries per shift.');
      }
      final seen = <String>{};
      final seenIds = <String>{};
      for (final item in input.items) {
        if (!seenIds.add(item.id)) problems.add('Duplicate earning entry ID.');
        if (item.amountCents < 0 && item.kind != IncomeKind.adjustment) {
          problems.add('Only correction entries can be negative.');
        }
        if (item.amountCents < -1000000000 || item.amountCents > 1000000000) {
          problems.add('Check individual income amount.');
        }
        final ref = item.reference.trim().toLowerCase();
        if (ref.isNotEmpty && !seen.add('${item.source.toLowerCase()}:$ref')) {
          problems.add('Duplicate transaction reference in ${item.source}.');
        }
      }
    }
    if (earnings != null && (earnings < 0 || earnings > 1000000000)) {
      problems.add('Review recorded earnings total.');
    }
    for (final value in <int?>[
      input.manualFuelCents,
      input.fuelPriceCents,
      input.otherCostCents,
      input.reservePerKmCents,
      input.targetCents,
    ]) {
      if (value != null && (value < 0 || value > 1000000000)) {
        problems.add(
          'Expenses and targets must be valid non-negative amounts.',
        );
      }
    }
    if (input.distanceKm != null &&
        (!input.distanceKm!.isFinite ||
            input.distanceKm! < 0 ||
            input.distanceKm! > 5000)) {
      problems.add('Check work-related distance.');
    }
    if (input.efficiencyKmL != null &&
        (!input.efficiencyKmL!.isFinite ||
            input.efficiencyKmL! <= 0 ||
            input.efficiencyKmL! > 1000)) {
      problems.add('Check motorcycle fuel efficiency.');
    }
    if (input.hours != null &&
        (!input.hours!.isFinite || input.hours! < 0 || input.hours! > 168)) {
      problems.add('Check working hours.');
    }
    if (problems.isNotEmpty) {
      return FinancialSnapshot(
        status: EstimateStatus.invalid,
        problems: problems,
        earningsCents: earnings,
      );
    }
    if (earnings == null) {
      return const FinancialSnapshot(
        status: EstimateStatus.empty,
        missing: ['Recorded earnings'],
      );
    }
    if (!input.afterPlatformFeesConfirmed) {
      return FinancialSnapshot(
        status: EstimateStatus.partial,
        earningsCents: earnings,
        missing: const ['Confirm whether platform fees are already deducted'],
      );
    }

    int? fuel;
    switch (input.fuelMethod) {
      case FuelMethod.unknown:
        missing.add('Fuel used for this shift');
        break;
      case FuelMethod.manual:
        fuel = input.manualFuelCents;
        if (fuel == null) missing.add('Estimated cost of fuel used');
        break;
      case FuelMethod.distance:
        if (input.distanceKm == null) missing.add('Work-related kilometers');
        if (input.efficiencyKmL == null) missing.add('Fuel efficiency');
        if (input.fuelPriceCents == null) {
          missing.add('Gasoline price per liter');
        }
        if (input.distanceKm != null &&
            input.efficiencyKmL != null &&
            input.fuelPriceCents != null) {
          final rawFuel =
              input.distanceKm! / input.efficiencyKmL! * input.fuelPriceCents!;
          if (!rawFuel.isFinite || rawFuel < 0 || rawFuel > 1000000000) {
            problems.add(
              'Calculated fuel cost is outside the supported range.',
            );
          } else {
            fuel = rawFuel.round();
          }
        }
        break;
    }
    if (input.otherCostCents == null) {
      missing.add('Other expenses (type 0 if none)');
    }
    int? reserve;
    if (input.reservePerKmCents == null) {
      missing.add('Maintenance allowance (0 if excluded)');
    } else if (input.reservePerKmCents == 0) {
      reserve = 0;
    } else if (input.distanceKm == null) {
      missing.add('Distance needed for maintenance allowance');
    } else {
      final rawReserve = input.distanceKm! * input.reservePerKmCents!;
      if (!rawReserve.isFinite || rawReserve < 0 || rawReserve > 1000000000) {
        problems.add(
          'Calculated maintenance allowance is outside the supported range.',
        );
      } else {
        reserve = rawReserve.round();
      }
    }
    if (problems.isNotEmpty) {
      return FinancialSnapshot(
        status: EstimateStatus.invalid,
        problems: problems,
        earningsCents: earnings,
      );
    }
    final cash = fuel != null && input.otherCostCents != null
        ? earnings - fuel - input.otherCostCents!
        : null;
    final after = cash != null && reserve != null ? cash - reserve : null;
    final status = fuel == null
        ? EstimateStatus.partial
        : (after == null ? EstimateStatus.rough : EstimateStatus.supported);
    return FinancialSnapshot(
      status: status,
      earningsCents: earnings,
      fuelCents: fuel,
      otherCents: input.otherCostCents,
      reserveCents: reserve,
      cashRemainderCents: cash,
      afterReserveCents: after,
      missing: missing,
    );
  }
}

class ShiftRecord {
  final String id;
  final DateTime workDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ShiftInput input;
  const ShiftRecord({
    required this.id,
    required this.workDate,
    required this.createdAt,
    required this.updatedAt,
    required this.input,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'workDate': workDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'input': input.toJson(),
  };

  factory ShiftRecord.fromJson(Map<String, dynamic> json) => ShiftRecord(
    id: json['id'] as String,
    workDate: DateTime.parse(json['workDate'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    input: ShiftInput.fromJson(Map<String, dynamic>.from(json['input'] as Map)),
  );
}
