/// Impact calculator using Nepal-specific metrics (2026).
class ImpactCalculator {
  static const Map<String, double> _categoryPricePerKg = {
    'vegetables': 100.0,
    'fruits': 200.0,
    'meat': 500.0,
    'grains': 130.0,
    'dairy': 300.0,
    'pulses': 140.0,
    'snacks': 180.0,
    'beverages': 120.0,
    'bakery': 160.0,
    'spices': 250.0,
  };

  static const double defaultPricePerKg = 210.0;
  static const double co2FactorPerKg = 2.5;

  static double toKg(double quantity, String unit) {
    switch (unit.toLowerCase().trim()) {
      case 'kg':
      case 'kgs':
        return quantity;
      case 'g':
      case 'grams':
      case 'gram':
        return quantity / 1000.0;
      case 'lb':
      case 'lbs':
      case 'pound':
      case 'pounds':
        return quantity * 0.4536;
      case 'l':
      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
        return quantity;
      case 'ml':
        return quantity / 1000.0;
      case 'pcs':
      case 'pieces':
      case 'piece':
      case 'items':
      case 'item':
      case 'nos':
        return quantity * 0.2;
      case 'dozen':
        return quantity * 12 * 0.06;
      case 'packet':
      case 'pack':
      case 'bag':
        return quantity * 0.5;
      default:
        return quantity * 0.2;
    }
  }

  static double priceForCategory(String? category) {
    if (category == null || category.isEmpty) return defaultPricePerKg;
    final key = category.toLowerCase().trim();

    if (_categoryPricePerKg.containsKey(key)) {
      return _categoryPricePerKg[key]!;
    }

    if (key.contains('veg') || key.contains('sabji') || key.contains('tarkari')) {
      return _categoryPricePerKg['vegetables']!;
    }
    if (key.contains('fruit') || key.contains('phal')) {
      return _categoryPricePerKg['fruits']!;
    }
    if (key.contains('meat') || key.contains('chicken') || key.contains('masu') ||
        key.contains('buff') || key.contains('fish') || key.contains('machha')) {
      return _categoryPricePerKg['meat']!;
    }
    if (key.contains('grain') || key.contains('rice') || key.contains('chamal') ||
        key.contains('wheat') || key.contains('flour') || key.contains('atta')) {
      return _categoryPricePerKg['grains']!;
    }
    if (key.contains('dairy') || key.contains('milk') || key.contains('dudh') ||
        key.contains('cheese') || key.contains('yogurt') || key.contains('dahi')) {
      return _categoryPricePerKg['dairy']!;
    }
    if (key.contains('pulse') || key.contains('dal') || key.contains('lentil') ||
        key.contains('bean')) {
      return _categoryPricePerKg['pulses']!;
    }
    if (key.contains('snack') || key.contains('biscuit') || key.contains('chips')) {
      return _categoryPricePerKg['snacks']!;
    }
    if (key.contains('drink') || key.contains('beverage') || key.contains('juice') ||
        key.contains('tea') || key.contains('coffee')) {
      return _categoryPricePerKg['beverages']!;
    }
    if (key.contains('bread') || key.contains('bakery') || key.contains('roti') ||
        key.contains('cake')) {
      return _categoryPricePerKg['bakery']!;
    }
    if (key.contains('spice') || key.contains('masala')) {
      return _categoryPricePerKg['spices']!;
    }

    return defaultPricePerKg;
  }

  static ImpactResult calculateFromDonations(List<Map<String, dynamic>> items) {
    double totalWeightKg = 0;
    double totalMoneySaved = 0;

    for (final item in items) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
      final unit = (item['unit'] as String?) ?? 'pcs';
      final category = item['category'] as String?;

      final weightKg = toKg(qty, unit);
      final pricePerKg = priceForCategory(category);

      totalWeightKg += weightKg;
      totalMoneySaved += weightKg * pricePerKg;
    }

    return ImpactResult(
      totalWeightKg: totalWeightKg,
      moneySavedNPR: totalMoneySaved,
      co2AvoidedKg: totalWeightKg * co2FactorPerKg,
    );
  }

  static ImpactResult calculateFromWeight(double weightKg, {String? category}) {
    final pricePerKg = priceForCategory(category);
    return ImpactResult(
      totalWeightKg: weightKg,
      moneySavedNPR: weightKg * pricePerKg,
      co2AvoidedKg: weightKg * co2FactorPerKg,
    );
  }
}

class ImpactResult {
  final double totalWeightKg;
  final double moneySavedNPR;
  final double co2AvoidedKg;

  const ImpactResult({
    required this.totalWeightKg,
    required this.moneySavedNPR,
    required this.co2AvoidedKg,
  });

  ImpactResult operator +(ImpactResult other) => ImpactResult(
        totalWeightKg: totalWeightKg + other.totalWeightKg,
        moneySavedNPR: moneySavedNPR + other.moneySavedNPR,
        co2AvoidedKg: co2AvoidedKg + other.co2AvoidedKg,
      );

  static const zero = ImpactResult(
    totalWeightKg: 0,
    moneySavedNPR: 0,
    co2AvoidedKg: 0,
  );
}
