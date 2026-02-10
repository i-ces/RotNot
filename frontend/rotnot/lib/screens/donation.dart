import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show cos, sin, asin, sqrt;
import '../main.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
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

// Helper to calculate distance between two points (Haversine formula)
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // km
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * asin(sqrt(a));
  return earthRadius * c;
}

double _toRadians(double degree) => degree * 3.141592653589793 / 180;

// ─── Donation Screen ────────────────────────────────────────────────────────

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  FoodBank? _selectedBank;

  // Location state
  double _userLat = LocationService.defaultLat;
  double _userLng = LocationService.defaultLng;
  bool _loadingLocation = true;
  bool _locationDenied = false;

  // Food banks state
  List<FoodBank> _foodBanks = [];
  bool _loadingFoodBanks = true;
  String? _foodBanksError;

  // Food items state
  List<FoodItem> _foodItems = [];
  bool _loadingFoodItems = false;
  String? _foodItemsError;

  // User role state
  String? _userRole;
  bool _loadingRole = true;

  // Donor donations state (for tracking their donation requests)
  List<dynamic> _donorDonations = [];
  bool _loadingDonorDonations = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole().then((_) {
      // Load data based on role
      if (_userRole == 'foodbank') {
        _loadPendingDonations();
      } else {
        _fetchLocation();
        _loadFoodBanks();
        _loadDonorDonations();
      }
    });
  }

  Future<void> _fetchUserRole() async {
    try {
      final profile = await ApiService.getUserProfile();
      setState(() {
        _userRole = profile['role'] as String?;
        _loadingRole = false;
      });
    } catch (e) {
      print('Failed to fetch user role: $e');
      setState(() {
        _userRole = 'user'; // Default to user if fetch fails
        _loadingRole = false;
      });
    }
  }

  Future<void> _loadDonorDonations() async {
    setState(() {
      _loadingDonorDonations = true;
    });

    try {
      final donations = await ApiService.getDonations();
      setState(() {
        _donorDonations = donations;
        _loadingDonorDonations = false;
      });
    } catch (e) {
      print('Error loading donor donations: $e');
      setState(() {
        _loadingDonorDonations = false;
      });
    }
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

  Future<void> _loadFoodBanks() async {
    try {
      setState(() {
        _loadingFoodBanks = true;
        _foodBanksError = null;
      });

      final response = await ApiService.getAllFoodBanks();

      final banks = response.map<FoodBank>((item) {
        final coords = item['location']['coordinates'] as List;
        final lng = coords[0] as double;
        final lat = coords[1] as double;

        // Calculate distance from user
        final distance = _calculateDistance(_userLat, _userLng, lat, lng);
        final distanceStr = distance < 1
            ? '${(distance * 1000).toStringAsFixed(0)} m away'
            : '${distance.toStringAsFixed(1)} km away';

        // Parse type
        FoodBankType type;
        switch (item['type']) {
          case 'charity':
            type = FoodBankType.charity;
            break;
          case 'shelter':
            type = FoodBankType.shelter;
            break;
          default:
            type = FoodBankType.community;
        }

        return FoodBank(
          id: item['_id'] as String,
          name: item['name'] as String,
          address: item['address'] as String,
          distance: distanceStr,
          openUntil: item['openUntil'] as String?,
          type: type,
          lat: lat,
          lng: lng,
        );
      }).toList();

      // Sort by distance
      banks.sort((a, b) {
        final distA = _calculateDistance(_userLat, _userLng, a.lat, a.lng);
        final distB = _calculateDistance(_userLat, _userLng, b.lat, b.lng);
        return distA.compareTo(distB);
      });

      if (mounted) {
        setState(() {
          _foodBanks = banks;
          _loadingFoodBanks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _foodBanksError = e.toString();
          _loadingFoodBanks = false;
        });
      }
    }
  }

  Future<void> _loadFoodItems() async {
    try {
      setState(() {
        _loadingFoodItems = true;
        _foodItemsError = null;
      });

      final response = await ApiService.getFoodItems();

      print('Loaded ${response.length} food items from API');
      if (response.isNotEmpty) {
        print('Sample item data: ${response.first}');
      }

      // Filter out items that are already donated or consumed at the backend level
      final availableItems = response.where((item) {
        final backendStatus = item['status'] as String?;
        return backendStatus != 'donated' && backendStatus != 'consumed';
      }).toList();

      print('After filtering backend status: ${availableItems.length} items');

      final items = <FoodItem>[];

      for (var i = 0; i < availableItems.length; i++) {
        try {
          final item = availableItems[i];

          // Safely extract ID (backend might return 'id' or '_id')
          final id = item['id']?.toString() ?? item['_id']?.toString();
          if (id == null || id.isEmpty) {
            print('Skipping item $i: missing id/_id. Keys: ${item.keys}');
            continue;
          }

          // Safely extract name
          final name = item['name']?.toString() ?? 'Unknown Item';

          // Parse dates safely with fallbacks
          DateTime addedDate;
          try {
            final addedAtStr = item['addedAt']?.toString();
            addedDate = addedAtStr != null
                ? DateTime.parse(addedAtStr)
                : DateTime.now();
          } catch (e) {
            print('Failed to parse addedAt for ${item['name']}: $e');
            addedDate = DateTime.now();
          }

          DateTime expiryDate;
          try {
            final expiryDateStr = item['expiryDate']?.toString();
            expiryDate = expiryDateStr != null
                ? DateTime.parse(expiryDateStr)
                : DateTime.now().add(const Duration(days: 7));
          } catch (e) {
            print('Failed to parse expiryDate for ${item['name']}: $e');
            expiryDate = DateTime.now().add(const Duration(days: 7));
          }

          // Safely extract quantity
          int quantity = 1;
          try {
            if (item['quantity'] != null) {
              quantity = (item['quantity'] as num).toInt();
            }
          } catch (e) {
            print('Failed to parse quantity for ${item['name']}: $e');
          }

          // Safely extract unit
          final unit = item['unit']?.toString() ?? 'unit';

          // Safely extract notes
          final notes = item['notes']?.toString();

          // Safely extract category
          final category = item['category']?.toString() ?? 'General';

          items.add(
            FoodItem(
              id: id,
              name: name,
              addedDate: addedDate,
              expiryDate: expiryDate,
              quantity: quantity,
              unit: unit,
              notes: notes,
              category: category,
            ),
          );
        } catch (e) {
          print('Error parsing item $i: $e');
          continue;
        }
      }

      print('Successfully parsed ${items.length} items');

      // Filter to only show fresh and expiring items (not expired)
      final donateableItems = items.where((item) {
        final status = item.status;
        final isDonatable =
            status == FoodStatus.fresh || status == FoodStatus.expiring;
        return isDonatable;
      }).toList();

      print(
        'Filtered to ${donateableItems.length} donateable items (fresh or expiring, not expired)',
      );
      for (var item in donateableItems) {
        print(
          ' - ${item.name}: ${item.status}, expires in ${item.daysLeft} days',
        );
      }

      if (mounted) {
        setState(() {
          _foodItems = donateableItems;
          _loadingFoodItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _foodItemsError = 'Error: $e';
          _loadingFoodItems = false;
        });
      }
      // Print for debugging
      print('Error loading food items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while fetching role
    if (_loadingRole) {
      return const Center(
        child: CircularProgressIndicator(color: MyApp.accentGreen),
      );
    }

    // Route to appropriate UI based on role
    if (_userRole == 'foodbank') {
      return _buildFoodBankReceivePage();
    } else {
      return _buildDonorPage(); // user or organization
    }
  }

  // ─── DONOR PAGE (User & Organization) ─────────────────────────────────────

  Widget _buildDonorPage() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDonorDonations();
        await _loadFoodBanks();
      },
      color: MyApp.accentGreen,
      backgroundColor: MyApp.scaffoldBg,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner ──
            _buildBanner(),
            const SizedBox(height: 24),

            // ── My Donations Section ──
            if (_donorDonations.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'My Donation Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MyApp.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_donorDonations.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: MyApp.accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._donorDonations.map(
                (donation) => _buildDonorDonationCard(donation),
              ),
              const SizedBox(height: 24),
            ],

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
            if (_loadingFoodBanks)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: MyApp.accentGreen),
                ),
              )
            else if (_foodBanksError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load food banks',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFoodBanks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyApp.accentGreen,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_foodBanks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No food banks available',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              )
            else
              ..._foodBanks.map((bank) => _buildFoodBankCard(bank)),
          ],
        ),
      ),
    );
  }

  // ─── FOOD BANK RECEIVE PAGE ──────────────────────────────────────────────

  Widget _buildFoodBankReceivePage() {
    return RefreshIndicator(
      onRefresh: _loadPendingDonations,
      color: MyApp.accentGreen,
      backgroundColor: MyApp.scaffoldBg,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Food Bank Banner ──
            _buildFoodBankBanner(),
            const SizedBox(height: 16),

            // ── Quick Stats ──
            if (!_loadingFoodItems && _foodItemsError == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pending_actions_rounded,
                      color: MyApp.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_foodItems.length} Pending ${_foodItems.length == 1 ? 'Request' : 'Requests'}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (_foodItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MyApp.accentGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Action Required',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: MyApp.accentGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ── Donation Requests Section ──
            const Text(
              'Incoming Donation Requests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ── Pending donations list ──
            if (_loadingFoodItems)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: MyApp.accentGreen),
                ),
              )
            else if (_foodItemsError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load donations',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingDonations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyApp.accentGreen,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_foodItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 80,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending donations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When donors send food, it will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._foodItems.map((item) => _buildDonationRequestCard(item)),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPendingDonations() async {
    setState(() {
      _loadingFoodItems = true;
      _foodItemsError = null;
    });

    try {
      final donations = await ApiService.getPendingDonations();

      // Convert donations to FoodItem objects
      // Each donation can have multiple food items, we'll show the first item as representative
      final items = <FoodItem>[];

      for (var donation in donations) {
        final donationId = donation['_id'] as String;
        final foodItems = donation['foodItems'] as List;

        if (foodItems.isNotEmpty) {
          final firstItem = foodItems[0];

          // Parse dates
          DateTime expiryDate;
          try {
            // Assuming the donation has a pickup scheduled date, use that as proxy for expiry
            final pickupStr = donation['pickupScheduledAt']?.toString();
            expiryDate = pickupStr != null
                ? DateTime.parse(pickupStr)
                : DateTime.now().add(const Duration(days: 3));
          } catch (e) {
            expiryDate = DateTime.now().add(const Duration(days: 3));
          }

          items.add(
            FoodItem(
              id: firstItem['foodItemId']?.toString() ?? donationId,
              name: firstItem['name']?.toString() ?? 'Food Item',
              addedDate: DateTime.now(),
              expiryDate: expiryDate,
              quantity: (firstItem['quantity'] as num?)?.toInt() ?? 1,
              unit: firstItem['unit']?.toString() ?? 'unit',
              category: 'Donation', // Default category for donations
              donationId: donationId, // Store donation ID for accept/decline
            ),
          );
        }
      }

      setState(() {
        _foodItems = items;
        _loadingFoodItems = false;
      });
    } catch (e) {
      print('Error loading pending donations: $e');
      setState(() {
        _foodItemsError = e.toString();
        _loadingFoodItems = false;
      });
    }
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

  Widget _buildFoodBankBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MyApp.accentGreen.withOpacity(0.2), const Color(0xFF1E1E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 48,
                color: MyApp.accentGreen,
              ),
              // Pending count badge
              if (!_loadingFoodItems && _foodItems.isNotEmpty)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _foodItems.length.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Receive Donations',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review and accept food donations from donors',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              Text(
                'Getting your location…',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
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
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                  // Food bank markers
                  ..._foodBanks.map(
                    (bank) => Marker(
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
                            border: Border.all(color: Colors.white, width: 2),
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
                    ),
                  ),
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
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
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
                  Text(
                    'Food Banks',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: MyApp.scaffoldBg.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 14,
                        color: MyApp.accentGreen,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Use my location',
                        style: TextStyle(
                          color: MyApp.accentGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),

            // Open hours + details
            Row(
              children: [
                if (bank.openUntil != null) ...[
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: MyApp.accentGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Open until ${bank.openUntil}',
                    style: const TextStyle(
                      color: MyApp.accentGreen,
                      fontSize: 12,
                    ),
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

  // ─── Donor Donation Card (for tracking sent donations) ───────────────────

  Widget _buildDonorDonationCard(dynamic donation) {
    final status = donation['status']?.toString() ?? 'pending';
    final foodBank = donation['foodBankId'] as Map<String, dynamic>?;
    final foodItems = donation['foodItems'] as List? ?? [];
    final createdAt = donation['createdAt']?.toString();

    // Status configuration
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = MyApp.accentGreen;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Accepted';
        break;
      case 'declined':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Rejected';
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule_rounded;
        statusText = 'Scheduled';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_rounded;
        statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyApp.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodBank?['name']?.toString() ?? 'Food Bank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (createdAt != null)
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Food items list
          if (foodItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fastfood_rounded,
                        size: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Donated Items',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...foodItems.map((item) {
                    final name = item['name']?.toString() ?? 'Unknown';
                    final quantity = item['quantity']?.toString() ?? '1';
                    final unit = item['unit']?.toString() ?? 'pcs';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: MyApp.accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$name ($quantity $unit)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Status message
          if (status.toLowerCase() == 'accepted') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MyApp.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    size: 16,
                    color: MyApp.accentGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your donation has been accepted! The food bank will arrange pickup.',
                      style: TextStyle(color: MyApp.accentGreen, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _clearDonationRequest(donation),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Clear from list'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else if (status.toLowerCase() == 'declined') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This donation request was declined. You can donate to another food bank.',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} min ago';
        }
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _clearDonationRequest(dynamic donation) async {
    try {
      // Call API to dismiss donation
      await ApiService.dismissDonation(donation['_id']);

      setState(() {
        _donorDonations.remove(donation);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Donation cleared from list'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear donation: $e'),
            backgroundColor: Colors.red[500],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ─── Donation Request Card (for food banks) ──────────────────────────────

  Widget _buildDonationRequestCard(FoodItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyApp.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MyApp.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFoodIcon(item.category),
                  color: MyApp.accentGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'From: Anonymous Donor',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getExpiryColor(item.expiryDate),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.expiryDate.difference(DateTime.now()).inDays}d left',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(Icons.category_outlined, item.category),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.scale_outlined, '${item.quantity}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _declineDonation(item),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptDonation(item),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyApp.accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  IconData _getFoodIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Icons.icecream_rounded;
      case 'vegetables':
        return Icons.eco_rounded;
      case 'fruits':
        return Icons.apple_rounded;
      case 'meat':
        return Icons.set_meal_rounded;
      case 'bakery':
        return Icons.bakery_dining_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  Color _getExpiryColor(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 2) return Colors.red.withOpacity(0.8);
    if (daysLeft <= 5) return Colors.orange.withOpacity(0.8);
    return MyApp.accentGreen.withOpacity(0.8);
  }

  Future<void> _acceptDonation(FoodItem item) async {
    if (item.donationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Donation ID not found'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: MyApp.accentGreen),
        ),
      );

      // Call API to accept donation
      await ApiService.acceptDonation(item.donationId!);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Accepted ${item.name}'),
          backgroundColor: MyApp.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Remove from list
      setState(() {
        _foodItems.remove(item);
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept donation: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _declineDonation(FoodItem item) async {
    final shouldDecline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Decline Donation?'),
        content: Text('Are you sure you want to decline ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Decline',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldDecline == true) {
      if (item.donationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Donation ID not found'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: MyApp.accentGreen),
          ),
        );

        // Call API to decline donation
        await ApiService.declineDonation(item.donationId!);

        if (!mounted) return;
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined ${item.name}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          _foodItems.remove(item);
        });
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ─── Item selection bottom sheet (shows after selecting a food bank) ─────

  Future<void> _showItemSelectionSheet(FoodBank bank) async {
    // Load food items if not already loaded or if there was an error
    if ((_foodItems.isEmpty || _foodItemsError != null) && !_loadingFoodItems) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: MyApp.accentGreen),
        ),
      );

      await _loadFoodItems();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Check if loading failed
        if (_foodItemsError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load food items: $_foodItemsError'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _showItemSelectionSheet(bank),
              ),
            ),
          );
          return;
        }
      }
    }

    final selected = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final expiringCount = _foodItems
                .where((i) => i.status != FoodStatus.fresh)
                .length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: MyApp.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                            horizontal: 10,
                            vertical: 4,
                          ),
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
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: MyApp.accentGreen,
                        ),
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
                    child: _foodItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No items available for donation',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add items to your shelf first',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _foodItems.length,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: true,
                            itemBuilder: (context, index) {
                              final item = _foodItems[index];
                              final isChecked = selected.contains(item.id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
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
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                          border: Border.all(
                                            color: isChecked
                                                ? MyApp.accentGreen
                                                : Colors.white30,
                                            width: 2,
                                          ),
                                        ),
                                        child: isChecked
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                                color: Colors.white,
                                              )
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
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 13,
                                                color: item.statusColor,
                                              ),
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
                                _submitDonation(
                                  bank,
                                  _foodItems
                                      .where((i) => selected.contains(i.id))
                                      .toList(),
                                );
                              },
                        icon: const Icon(
                          Icons.local_shipping_rounded,
                          size: 20,
                        ),
                        label: Text(
                          selected.isEmpty
                              ? 'Select items to donate'
                              : 'Send request (${selected.length} items)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyApp.accentGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: MyApp.accentGreen
                              .withOpacity(0.3),
                          disabledForegroundColor: Colors.white38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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

  // ─── Submit donation ──────────────────────────────────────────────────────

  Future<void> _submitDonation(FoodBank bank, List<FoodItem> items) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: MyApp.accentGreen),
      ),
    );

    try {
      final donationData = {
        'foodBankId': bank.id,
        'foodItems': items
            .map(
              (item) => {
                'foodItemId': item.id,
                'quantity': item.quantity,
                'unit': item.unit,
              },
            )
            .toList(),
        'notes': 'Scheduled via RotNot app',
      };

      await ApiService.createDonation(donationData);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showPickupConfirmation(bank, items);

        // Reload food items to update the list
        _loadFoodItems();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create donation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Pickup confirmation dialog ───────────────────────────────────────────

  void _showPickupConfirmation(FoodBank bank, List<FoodItem> items) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MyApp.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MyApp.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: MyApp.accentGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Request Sent!',
                  style: TextStyle(
                    color: Colors.yellow,
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
                Icons.inventory_2_outlined,
                '${items.length} items selected',
              ),
              const SizedBox(height: 10),
              _confirmRow(Icons.access_time_rounded, 'Pickup within 2 hours'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MyApp.accentGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MyApp.accentGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      color: MyApp.accentGreen,
                      size: 20,
                    ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
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
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
