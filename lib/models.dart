// ─── Vehicle Model ───────────────────────────────────────────────────────────
class Vehicle {
  final String id;
  final String name;
  final String brand;
  final String category; // Coupe, SUV, Sedan, Sports
  final double horsepower;
  final double zeroToSixty; // seconds
  final double monthlyPrice;
  final String imageUrl;
  final String description;
  final bool isAvailable;
  final List<String> features;
  final double rating;
  final int reviewCount;
  final String color;
  final int year;

  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.horsepower,
    required this.zeroToSixty,
    required this.monthlyPrice,
    required this.imageUrl,
    required this.description,
    this.isAvailable = true,
    this.features = const [],
    this.rating = 4.8,
    this.reviewCount = 124,
    this.color = 'Midnight Black',
    this.year = 2024,
  });
}

// ─── Subscription Tier ───────────────────────────────────────────────────────
enum SubscriptionTier { basic, premium, elite }

extension SubscriptionTierExt on SubscriptionTier {
  String get name {
    switch (this) {
      case SubscriptionTier.basic:
        return 'Basic';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.elite:
        return 'Elite';
    }
  }

  double get price {
    switch (this) {
      case SubscriptionTier.basic:
        return 129;
      case SubscriptionTier.premium:
        return 249;
      case SubscriptionTier.elite:
        return 449;
    }
  }

  int get swapsPerMonth {
    switch (this) {
      case SubscriptionTier.basic:
        return 1;
      case SubscriptionTier.premium:
        return 3;
      case SubscriptionTier.elite:
        return 999; // unlimited
    }
  }

  List<String> get perks {
    switch (this) {
      case SubscriptionTier.basic:
        return ['1 swap/month', 'Sedans & SUVs', 'Basic insurance', '24/7 support'];
      case SubscriptionTier.premium:
        return [
          '3 swaps/month',
          'Sports & Coupes',
          'Full coverage',
          'Priority support',
          'Free delivery',
        ];
      case SubscriptionTier.elite:
        return [
          'Unlimited swaps',
          'All vehicles incl. exotics',
          'Concierge service',
          'Airport pickup',
          'Dedicated manager',
          'Event access',
        ];
    }
  }
}

// ─── Booking Model ────────────────────────────────────────────────────────────
class Booking {
  final String id;
  final Vehicle vehicle;
  final DateTime startDate;
  final DateTime? endDate;
  final BookingStatus status;
  final double totalCost;

  const Booking({
    required this.id,
    required this.vehicle,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.totalCost,
  });
}

enum BookingStatus { active, completed, upcoming, cancelled }

extension BookingStatusExt on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// ─── App User Model ───────────────────────────────────────────────────────────
class AppUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final SubscriptionTier tier;
  final DateTime renewalDate;
  final List<Booking> bookings;
  final bool isAdmin;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.tier,
    required this.renewalDate,
    this.bookings = const [],
    this.isAdmin = false,
  });
}

// ─── Sample Data ──────────────────────────────────────────────────────────────
class SampleData {
  static const List<Vehicle> vehicles = [
    Vehicle(
      id: 'v1',
      name: '911 Carrera S',
      brand: 'Porsche',
      category: 'Sports',
      horsepower: 450,
      zeroToSixty: 3.5,
      monthlyPrice: 449,
      imageUrl: 'https://images.unsplash.com/photo-1614162692292-7ac56d7f7f1e?w=800',
      description:
      'The iconic 911 Carrera S combines timeless design with breathtaking performance. Pure driving pleasure, every mile.',
      features: ['Sport Chrono Package', 'PASM Sport Suspension', 'Sport Exhaust', 'Bose Surround'],
      color: 'GT Silver',
      year: 2024,
    ),
    Vehicle(
      id: 'v2',
      name: 'CT5-V Blackwing',
      brand: 'Cadillac',
      category: 'Sedan',
      horsepower: 668,
      zeroToSixty: 3.7,
      monthlyPrice: 349,
      imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800',
      description:
      'American muscle meets luxury. The CT5-V Blackwing is the most powerful Cadillac production car ever built.',
      features: ['Magnetic Ride Control', 'Carbon Fiber Package', 'Brembo Brakes', 'Head-Up Display'],
      color: 'Infrared Tintcoat',
      year: 2024,
    ),
    Vehicle(
      id: 'v3',
      name: 'M3 Competition',
      brand: 'BMW',
      category: 'Sedan',
      horsepower: 503,
      zeroToSixty: 3.4,
      monthlyPrice: 399,
      imageUrl: 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800',
      description:
      'The BMW M3 Competition xDrive is an uncompromising performance sedan with all-weather capability.',
      features: ['M xDrive AWD', 'Carbon Bucket Seats', 'M Track Package', 'Harman Kardon'],
      color: 'Frozen Portimao Blue',
      year: 2024,
    ),
    Vehicle(
      id: 'v4',
      name: 'Cayenne Turbo GT',
      brand: 'Porsche',
      category: 'SUV',
      horsepower: 640,
      zeroToSixty: 3.1,
      monthlyPrice: 549,
      imageUrl: 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800',
      description:
      'The fastest production SUV in the world. Track performance meets everyday luxury in the Cayenne Turbo GT.',
      features: ['PDCC Sport', 'Torque Vectoring', 'Carbon Roof', 'Sport Design Package'],
      color: 'Onyx Black',
      year: 2024,
    ),
    Vehicle(
      id: 'v5',
      name: 'AMG GT 63 S',
      brand: 'Mercedes',
      category: 'Coupe',
      horsepower: 630,
      zeroToSixty: 3.1,
      monthlyPrice: 529,
      imageUrl: 'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?w=800',
      description:
      'Four-door coupe redefined. The AMG GT 63 S E Performance blends electrification with pure AMG DNA.',
      features: ['AMG Ride Control+', 'Aerodynamic Package', 'AMG Track Pace', 'Burmester 3D'],
      color: 'Obsidian Black',
      year: 2024,
    ),
    Vehicle(
      id: 'v6',
      name: 'Urus Performante',
      brand: 'Lamborghini',
      category: 'SUV',
      horsepower: 657,
      zeroToSixty: 3.3,
      monthlyPrice: 749,
      imageUrl: 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=800',
      description:
      'The Urus Performante is the world\'s first Super Sport Utility Vehicle. Built for those who refuse to compromise.',
      features: ['Torque Vectoring+', 'Carbon Ceramic Brakes', 'Sport Exhaust', 'Alcantara Interior'],
      color: 'Arancio Borealis',
      year: 2024,
    ),
  ];

  static final AppUser currentUser = AppUser(
    id: 'u1',
    name: 'Ahmed Raza',
    email: 'ahmed.raza@gmail.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
    tier: SubscriptionTier.elite,
    renewalDate: DateTime.now().add(const Duration(days: 18)),
    bookings: [
      Booking(
        id: 'b1',
        vehicle: vehicles[0],
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        status: BookingStatus.active,
        totalCost: 449,
      ),
      Booking(
        id: 'b2',
        vehicle: vehicles[1],
        startDate: DateTime.now().subtract(const Duration(days: 35)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        status: BookingStatus.completed,
        totalCost: 349,
      ),
      Booking(
        id: 'b3',
        vehicle: vehicles[2],
        startDate: DateTime.now().subtract(const Duration(days: 70)),
        endDate: DateTime.now().subtract(const Duration(days: 35)),
        status: BookingStatus.completed,
        totalCost: 399,
      ),
    ],
  );

  // Admin stats
  static const Map<String, dynamic> adminStats = {
    'totalRevenue': 142800.0,
    'totalBookings': 1547,
    'activeSubscribers': 312,
    'fleetSize': 150,
    'satisfiedClients': 99,
    'monthlyGrowth': 18.4,
    'revenueGrowth': 23.1,
    'pendingSwaps': 14,
  };

  static final List<Map<String, dynamic>> revenueData = List.generate(
    7,
        (i) => {
      'month': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'][i],
      'revenue': [85000, 92000, 98000, 105000, 118000, 132000, 142800][i],
    },
  );
}