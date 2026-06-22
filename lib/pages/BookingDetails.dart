import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AppTheme.dart';
import '../models.dart';
import '../commonWidgets.dart';


class BookingDetailsPage extends StatefulWidget {
  final Vehicle vehicle;

  const BookingDetailsPage({super.key, required this.vehicle});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = '10:00 AM';
  String _selectedLocation = 'Home Delivery';
  bool _submitting = false;

  final List<String> _timeSlots = ['08:00 AM', '10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM', '06:00 PM'];
  final List<String> _locations = ['Office Delivery', 'Veloce Automotives – Wapda Town', 'Veloce Hub – khyban-e-Ameen'];

  Future<void> _confirmBooking() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You must be signed in to book a vehicle.'),
        backgroundColor: VeloceTheme.accentRed,
      ));
      return;
    }

    setState(() => _submitting = true);

    try {
      // ─── Re-check live availability ────────────────────────────────────
      // The admin may have toggled this vehicle to unavailable after the
      // user opened this page but before they tapped Confirm. We re-read
      // the document right before writing the booking so a race condition
      // can't slip a booking through for an unavailable car.
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .get();

      final isStillAvailable = vehicleDoc.exists && (vehicleDoc.data()?['isAvailable'] as bool? ?? false);

      if (!isStillAvailable) {
        if (mounted) {
          setState(() => _submitting = false);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: VeloceTheme.bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('No Longer Available', style: TextStyle(color: VeloceTheme.textPrimary, fontWeight: FontWeight.w700)),
              content: const Text(
                'This vehicle was just booked by someone else or marked unavailable. Please choose another vehicle.',
                style: TextStyle(color: VeloceTheme.textSecondary, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // back to vehicle list/detail
                  },
                  child: const Text('Go Back', style: TextStyle(color: VeloceTheme.accentBlueBright, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }
        return;
      }

      // ─── Write the booking ──────────────────────────────────────────────
      final booking = BookingRecord(
        id: '', // Firestore assigns this
        vehicleId: widget.vehicle.id,
        vehicleName: widget.vehicle.name,
        vehicleBrand: widget.vehicle.brand,
        vehicleImageUrl: widget.vehicle.imageUrl,
        userId: firebaseUser.uid,
        userName: firebaseUser.displayName ?? 'Unknown',
        userEmail: firebaseUser.email ?? 'Unknown',
        pickupDate: _selectedDate,
        timeSlot: _selectedSlot,
        location: _selectedLocation,
        status: BookingStatus.pending,
      );

      final bookingMap = booking.toMap();
      bookingMap['createdAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('bookings').add(bookingMap);

      if (mounted) {
        setState(() => _submitting = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationPage(
              vehicle: widget.vehicle,
              date: _selectedDate,
              slot: _selectedSlot,
              location: _selectedLocation,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: VeloceTheme.accentRed,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: VeloceTheme.bgDeep,
        title: const Text('Schedule Details', style: TextStyle(color: VeloceTheme.textPrimary, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VeloceTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Vehicle summary ───────────────────────────────────────────
            GlassCard(
              borderColor: VeloceTheme.accentBlue.withOpacity(0.3),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.vehicle.imageUrl,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 60,
                        color: VeloceTheme.bgElevated,
                        child: const Icon(Icons.directions_car, color: VeloceTheme.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.vehicle.brand, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 12)),
                        Text(widget.vehicle.name, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('${widget.vehicle.perDayCharges.toInt()} PKR/day', style: const TextStyle(color: VeloceTheme.accentBlueBright, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── Booked under (auto-filled, read-only) ──────────────────────
            const Text('Booking Under', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  _InfoRow(icon: Icons.person_outline, label: 'Name', value: firebaseUser?.displayName ?? 'Unknown'),
                  const Divider(color: VeloceTheme.borderColor, height: 16),
                  _InfoRow(icon: Icons.mail_outline, label: 'Email', value: firebaseUser?.email ?? 'Unknown'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Date picker ────────────────────────────────────────────────
            const Text('Pickup Date', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 10,
                itemBuilder: (ctx, i) {
                  final d = DateTime.now().add(Duration(days: i + 1));
                  final sel = d.day == _selectedDate.day && d.month == _selectedDate.month;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      width: 56,
                      decoration: BoxDecoration(
                        color: sel ? VeloceTheme.accentBlue : VeloceTheme.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? VeloceTheme.accentBlue : VeloceTheme.borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1],
                            style: TextStyle(color: sel ? Colors.white70 : VeloceTheme.textMuted, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d.day}',
                            style: TextStyle(color: sel ? Colors.white : VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ─── Time slot ───────────────────────────────────────────────────
            const Text('Time Slot', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((t) {
                final sel = t == _selectedSlot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? VeloceTheme.accentBlue : VeloceTheme.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? VeloceTheme.accentBlue : VeloceTheme.borderColor),
                    ),
                    child: Text(t, style: TextStyle(color: sel ? Colors.white : VeloceTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ─── Location ────────────────────────────────────────────────────
            const Text('Delivery Location', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...(_locations.map((l) {
              final sel = l == _selectedLocation;
              return GestureDetector(
                onTap: () => setState(() => _selectedLocation = l),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? VeloceTheme.accentBlue.withOpacity(0.1) : VeloceTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? VeloceTheme.accentBlue : VeloceTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(sel ? Icons.location_on : Icons.location_on_outlined, color: sel ? VeloceTheme.accentBlueBright : VeloceTheme.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Text(l, style: TextStyle(color: sel ? VeloceTheme.textPrimary : VeloceTheme.textSecondary, fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            })),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: VeloceButton(
                label: 'Confirm Booking',
                onPressed: _submitting ? null : _confirmBooking,
                isLoading: _submitting,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: VeloceTheme.textMuted, size: 16),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Confirmation Page ─────────────────────────────────────────────────────────
class BookingConfirmationPage extends StatelessWidget {
  final Vehicle vehicle;
  final DateTime date;
  final String slot;
  final String location;

  const BookingConfirmationPage({
    super.key,
    required this.vehicle,
    required this.date,
    required this.slot,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(color: VeloceTheme.successGreen.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: VeloceTheme.successGreen, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Booking Confirmed!', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'Our team has been notified and will reach out to confirm pickup details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VeloceTheme.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(vehicle.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),

              GlassCard(
                child: Column(
                  children: [
                    _ConfirmRow('Vehicle', '${vehicle.brand} ${vehicle.name}'),
                    const Divider(color: VeloceTheme.borderColor, height: 16),
                    _ConfirmRow('Date', '${date.day} ${months[date.month - 1]} ${date.year}'),
                    const Divider(color: VeloceTheme.borderColor, height: 16),
                    _ConfirmRow('Time', slot),
                    const Divider(color: VeloceTheme.borderColor, height: 16),
                    _ConfirmRow('Location', location),
                  ],
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: VeloceButton(
                  label: 'Back to Home',
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfirmRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}