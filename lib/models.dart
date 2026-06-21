// ─── Vehicle Model ───────────────────────────────────────────────────────────
class Vehicle {
  final String id;
  final String name;
  final String brand;
  final String category; // Coupe, SUV, Sedan, Sports, Truck
  final double horsepower;
  final double zeroToSixty; // seconds
  final double perDayCharges;
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
    required this.perDayCharges,
    required this.imageUrl,
    required this.description,
    this.isAvailable = true,
    this.features = const [],
    this.rating = 4.8,
    this.reviewCount = 124,
    this.color = 'Midnight Black',
    this.year = 2024,
  });

  /// Construct a [Vehicle] from a Firestore document snapshot.
  /// Field names must match exactly what the admin panel writes to Firestore.
  factory Vehicle.fromFirestore(Map<String, dynamic> data, String docId) {
    return Vehicle(
      id: docId,
      name: data['name'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      category: data['category'] as String? ?? 'Sports',
      horsepower: (data['horsepower'] as num?)?.toDouble() ?? 0,
      zeroToSixty: (data['zeroToSixty'] as num?)?.toDouble() ?? 0,
      perDayCharges: (data['perDayCharges'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? true,
      features: List<String>.from(data['features'] as List? ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      color: data['color'] as String? ?? 'Midnight Black',
      year: (data['year'] as num?)?.toInt() ?? 2024,
    );
  }

  /// Convert to a Map for writing to Firestore from the admin panel.
  Map<String, dynamic> toMap() => {
    'name': name,
    'brand': brand,
    'category': category,
    'horsepower': horsepower,
    'zeroToSixty': zeroToSixty,
    'perDayCharges': perDayCharges,
    'imageUrl': imageUrl,
    'description': description,
    'isAvailable': isAvailable,
    'features': features,
    'rating': rating,
    'reviewCount': reviewCount,
    'color': color,
    'year': year,
  };
}

// ─── Booking Status ───────────────────────────────────────────────────────────
enum BookingStatus { pending, confirmed, completed, cancelled }

extension BookingStatusExt on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  static BookingStatus fromString(String? value) {
    switch (value) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }
}

// ─── Booking Record ───────────────────────────────────────────────────────────
/// A booking created when a user books a vehicle and fills in schedule
/// details. Written to the Firestore `bookings` collection; the admin
/// dashboard listens to this collection live to show new requests.
class BookingRecord {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final String vehicleBrand;
  final String vehicleImageUrl;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime pickupDate;
  final String timeSlot;
  final String location;
  final BookingStatus status;
  final DateTime? createdAt;

  const BookingRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleBrand,
    required this.vehicleImageUrl,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.pickupDate,
    required this.timeSlot,
    required this.location,
    this.status = BookingStatus.pending,
    this.createdAt,
  });

  factory BookingRecord.fromFirestore(Map<String, dynamic> data, String docId) {
    return BookingRecord(
      id: docId,
      vehicleId: data['vehicleId'] as String? ?? '',
      vehicleName: data['vehicleName'] as String? ?? '',
      vehicleBrand: data['vehicleBrand'] as String? ?? '',
      vehicleImageUrl: data['vehicleImageUrl'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      pickupDate: data['pickupDate'] != null
          ? (data['pickupDate'] as dynamic).toDate() as DateTime
          : DateTime.now(),
      timeSlot: data['timeSlot'] as String? ?? '',
      location: data['location'] as String? ?? '',
      status: BookingStatusExt.fromString(data['status'] as String?),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate() as DateTime
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'vehicleId': vehicleId,
    'vehicleName': vehicleName,
    'vehicleBrand': vehicleBrand,
    'vehicleImageUrl': vehicleImageUrl,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'pickupDate': pickupDate,
    'timeSlot': timeSlot,
    'location': location,
    'status': status.value,
  };
}

// ─── App User (Firestore-backed) ──────────────────────────────────────────────
/// Represents a real signed-up user, read from Firestore `users/{uid}`.
/// This replaces the old mock AppUser/SubscriptionTier system entirely.
class AppUser {
  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String docId) {
    return AppUser(
      id: docId,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate() as DateTime
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'createdAt': createdAt,
  };
}