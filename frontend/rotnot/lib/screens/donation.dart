import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import '../services/location_service.dart';
import 'shelf.dart';

// ─── Food Bank model ────────────────────────────────────────────────────────

enum FoodBankType { community, charity, shelter }

class FoodBank {
  final String id;
  final String name;
  final String distance;
  final String? openUntil;
  final FoodBankType type;
  final String address;
  final double lat;
  final double lng;

  const FoodBank({
    required this.id,
    required this.name,
    required this.distance,
    this.openUntil,
    required this.type,
    required this.address,
    required this.lat,
    required this.lng,
  });

  String get typeLabel {
    switch (type) {
      case FoodBankType.community:
        return 'COMMUNITY';
      case FoodBankType.charity:
        return 'CHARITY';
      case FoodBankType.shelter:
        return 'SHELTER';
    }
  }

  Color get typeColor {
    switch (type) {
      case FoodBankType.community:
        return MyApp.accentGreen;
      case FoodBankType.charity:
        return const Color(0xFF3498DB);
      case FoodBankType.shelter:
        return const Color(0xFFF39C12);
    }
  }
}

// ─── Sample food banks ──────────────────────────────────────────────────────

const _sampleFoodBanks = <FoodBank>[
  FoodBank(
    id: '1',
    name: 'Kathmandu Community Fridge',
    distance: '0.8 km away',
    openUntil: '8:00 PM',
    type: FoodBankType.community,
    address: 'Thamel, Kathmandu',
    lat: 27.7172,
    lng: 85.3240,
  ),
  FoodBank(
    id: '2',
    name: 'Patan Food Bank',
    distance: '1.5 km away',
    openUntil: '6:00 PM',
    type: FoodBankType.charity,
    address: 'Mangalbazar, Lalitpur',
    lat: 27.6727,
    lng: 85.3286,
  ),
  FoodBank(
    id: '3',
    name: 'Bhaktapur Shelter Kitchen',
    distance: '3.2 km away',
    openUntil: '9:00 PM',
    type: FoodBankType.shelter,
    address: 'Durbar Square, Bhaktapur',
    lat: 27.6722,
    lng: 85.4298,
  ),
  FoodBank(
    id: '4',
    name: 'Balaju Community Center',
    distance: '4.0 km away',
    openUntil: '5:00 PM',
    type: FoodBankType.community,
    address: 'Balaju, Kathmandu',
    lat: 27.7350,
    lng: 85.3050,
  ),
];

// ─── Sample expiring items (shared with shelf concept) ──────────────────────

List<FoodItem> _expiringFoodItems() {
  final now = DateTime.now();
  return [
    FoodItem(
      id: 'd1',
      name: 'Organic Whole Milk',
      addedDate: now.subtract(const Duration(days: 3)),
      expiryDate: now.add(const Duration(days: 2)),
      quantity: 1,
      unit: 'litre',
    ),
    FoodItem(
      id: 'd2',
      name: 'Sourdough Loaf',
      addedDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.add(const Duration(days: 1)),
      quantity: 1,
      unit: 'unit',
    ),
    FoodItem(
      id: 'd3',
      name: 'Fresh Baby Spinach',
      addedDate: now.subtract(const Duration(days: 4)),
      expiryDate: now,
      quantity: 200,
      unit: 'g',
    ),
    FoodItem(
      id: 'd4',
      name: 'Yogurt Cup',
      addedDate: now.subtract(const Duration(days: 5)),
      expiryDate: now.add(const Duration(days: 1)),
      quantity: 2,
      unit: 'cups',
    ),
    FoodItem(
      id: 'd5',
      name: 'Sliced Bread',
      addedDate: now.subtract(const Duration(days: 3)),
      expiryDate: now.add(const Duration(days: 3)),
      quantity: 1,
      unit: 'pack',
    ),
  ];
}

// ─── Donation Screen ────────────────────────────────────────────────────────

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  FoodBank? _selectedBank;
  bool _showListView = true;

  // Location state
  double _userLat = LocationService.defaultLat;
  double _userLng = LocationService.defaultLng;
  bool _loadingLocation = true;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          if (position != null) {
            _userLat = position.latitude;
            _userLng = position.longitude;
          } else {
            // Couldn't get location — use default (Kathmandu)
            _locationDenied = true;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _locationDenied = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ──
          _buildBanner(),
          const SizedBox(height: 24),

          // ── Nearby Food Banks header ──
          const Text(
            'Nearby Food Banks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // ── Map ──
          _buildMapSection(),
          const SizedBox(height: 16),

          // ── Food bank list ──
          ..._sampleFoodBanks.map((bank) => _buildFoodBankCard(bank)),
        ],
      ),
    );
  }

  // ─── Banner ───────────────────────────────────────────────────────────────

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MyApp.accentGreen.withOpacity(0.25),
            MyApp.accentGreen.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MyApp.accentGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MyApp.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'COMMUNITY ACTION',
              style: TextStyle(
                color: MyApp.accentGreen,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reduce Waste,\nFeed the Soul.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Donate surplus food to people in need',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── View toggle ──────────────────────────────────────────────────────────

  Widget _viewToggle(IconData icon, bool isListView) {
    final isActive = _showListView == isListView;
    return GestureDetector(
      onTap: () => setState(() => _showListView = isListView),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? MyApp.accentGreen.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: isActive ? MyApp.accentGreen : Colors.white38),
      ),
    );
  }

  // ─── Real map with OpenStreetMap ──────────────────────────────────────────

  Widget _buildMapSection() {
    if (_loadingLocation) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: MyApp.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: MyApp.accentGreen,
                  strokeWidth: 2.5,
                ),
              ),
              SizedBox(height: 12),
              Text('Getting your location…',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(_userLat, _userLng),
              initialZoom: 12.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rotnot.app',
              ),
              MarkerLayer(
                markers: [
                  // User location marker
                  Marker(
                    point: LatLng(_userLat, _userLng),
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 14),
                    ),
                  ),
                  // Food bank markers
                  ..._sampleFoodBanks.map((bank) => Marker(
                        point: LatLng(bank.lat, bank.lng),
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedBank = bank);
                            _showItemSelectionSheet(bank);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: bank.typeColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: bank.typeColor.withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.food_bank_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
          // Legend + location status
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MyApp.scaffoldBg.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _locationDenied ? 'Default location' : 'You',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: MyApp.accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('Food Banks', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                ],
              ),
            ),
          ),
          // Retry button if location denied
          if (_locationDenied)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _loadingLocation = true;
                    _locationDenied = false;
                  });
                  _fetchLocation();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: MyApp.scaffoldBg.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location_rounded, size: 14, color: MyApp.accentGreen),
                      const SizedBox(width: 5),
                      Text('Use my location', style: TextStyle(color: MyApp.accentGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Food bank card ───────────────────────────────────────────────────────

  Widget _buildFoodBankCard(FoodBank bank) {
    final isSelected = _selectedBank?.id == bank.id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedBank = bank);
        _showItemSelectionSheet(bank);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyApp.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? MyApp.accentGreen.withOpacity(0.5)
                : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + type badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    bank.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bank.typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bank.typeLabel,
                    style: TextStyle(
                      color: bank.typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Distance
            Text(
              bank.distance,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Open hours + details
            Row(
              children: [
                if (bank.openUntil != null) ...[
                  Icon(Icons.access_time_rounded,
                      size: 14, color: MyApp.accentGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Open until ${bank.openUntil}',
                    style: const TextStyle(
                        color: MyApp.accentGreen, fontSize: 12),
                  ),
                ],
                const Spacer(),
                Text(
                  'Select →',
                  style: TextStyle(
                    color: MyApp.accentGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Item selection bottom sheet (shows after selecting a food bank) ─────

  void _showItemSelectionSheet(FoodBank bank) {
    final items = _expiringFoodItems();
    final selected = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final expiringCount =
                items.where((i) => i.status != FoodStatus.fresh).length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: MyApp.surfaceColor,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select Items to Donate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF39C12).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$expiringCount Expiring Soon',
                            style: const TextStyle(
                              color: Color(0xFFF39C12),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Donating to label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: MyApp.accentGreen),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Donating to: ${bank.name}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Item list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isChecked = selected.contains(item.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: MyApp.scaffoldBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isChecked
                                  ? MyApp.accentGreen.withOpacity(0.4)
                                  : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    if (isChecked) {
                                      selected.remove(item.id);
                                    } else {
                                      selected.add(item.id);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? MyApp.accentGreen
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: isChecked
                                          ? MyApp.accentGreen
                                          : Colors.white30,
                                      width: 2,
                                    ),
                                  ),
                                  child: isChecked
                                      ? const Icon(Icons.check_rounded,
                                          size: 18, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Item details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.schedule_rounded,
                                            size: 13,
                                            color: item.statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.daysLeftLabel,
                                          style: TextStyle(
                                            color: item.statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity
                              Text(
                                '${item.quantity}${item.unit}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Schedule Pickup button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: selected.isEmpty
                            ? null
                            : () {
                                Navigator.pop(context);
                                _showPickupConfirmation(
                                  bank,
                                  items
                                      .where(
                                          (i) => selected.contains(i.id))
                                      .toList(),
                                );
                              },
                        icon: const Icon(Icons.local_shipping_rounded,
                            size: 20),
                        label: Text(
                          selected.isEmpty
                              ? 'Select items to donate'
                              : 'Schedule Pickup (${selected.length} items)',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyApp.accentGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              MyApp.accentGreen.withOpacity(0.3),
                          disabledForegroundColor: Colors.white38,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      "We'll notify a volunteer to collect your donation",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Pickup confirmation dialog ───────────────────────────────────────────

  void _showPickupConfirmation(FoodBank bank, List<FoodItem> items) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MyApp.surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MyApp.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: MyApp.accentGreen, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pickup Scheduled!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _confirmRow(Icons.location_on_rounded, bank.name),
              const SizedBox(height: 10),
              _confirmRow(
                  Icons.inventory_2_outlined, '${items.length} items selected'),
              const SizedBox(height: 10),
              _confirmRow(Icons.access_time_rounded, 'Pickup within 2 hours'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MyApp.accentGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: MyApp.accentGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_rounded,
                        color: MyApp.accentGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thank you for reducing food waste! 🌱',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyApp.accentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Done',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _confirmRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
        ),
      ],
    );
  }
}


