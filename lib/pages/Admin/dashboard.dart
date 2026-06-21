import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../AppTheme.dart';
import '../../models.dart';
import '../../commonWidgets.dart';
import 'CRUD.dart';
import 'userHandling.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  int _selectedNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _adminPages;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animCtrl.forward();

    _adminPages = [
      _DashboardContent(
        onTabSelected: (index) {
          setState(() => _selectedNavIndex = index);
        },
      ),
      const AdminFleetScreen(),
      const AdminUsersScreen(),
    ];
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: VeloceTheme.bgDeep,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
            child:
              _VeloceLogo(),

        ),
        leadingWidth: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Panel', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Veloce Operations', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 11)),
          ],
        ),
        actions: [
          // ─── Live notification bell — badge count = pending bookings ───────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').where('status', isEqualTo: 'pending').snapshots(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: VeloceTheme.textPrimary),
                    onPressed: () => setState(() => _selectedNavIndex = 0),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(color: VeloceTheme.accentRed, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            pendingCount > 9 ? '9+' : '$pendingCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: VeloceTheme.accentBlue.withOpacity(0.2),
              child: const Text('A', style: TextStyle(color: VeloceTheme.accentBlueBright, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _adminPages[_selectedNavIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: VeloceTheme.bgCard,
          border: Border(top: BorderSide(color: VeloceTheme.borderColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (i) => setState(() => _selectedNavIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), activeIcon: Icon(Icons.directions_car), label: 'Fleet'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Content ────────────────────────────────────────────────────────
class _DashboardContent extends StatelessWidget {
  final Function(int) onTabSelected;

  const _DashboardContent({required this.onTabSelected});

  void _simulateExportReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 16),
            Text('Compiling system operations report...', style: TextStyle(color: Colors.white)),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veloce_Operations_Report.csv downloaded to device storage!'),
          backgroundColor: VeloceTheme.successGreen,
        ),
      );
    });
  }

  // ─── Mark a booking as confirmed (and free up / keep vehicle state) ────────
  Future<void> _updateBookingStatus(BuildContext context, String bookingId, String newStatus) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': newStatus});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Booking marked as $newStatus.'),
        backgroundColor: VeloceTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
      builder: (context, vehicleSnapshot) {
        final vehicleDocs = vehicleSnapshot.data?.docs ?? [];
        final totalVehicles = vehicleDocs.length;

        final List<Vehicle> currentFleet = vehicleDocs.map((doc) {
          return Vehicle.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        final availableCount = currentFleet.where((v) => v.isAvailable).length;
        final inUseCount = currentFleet.where((v) => !v.isAvailable).length;

        final sportsCount = currentFleet.where((v) => v.category.toLowerCase() == 'sports').length;
        final sedanCount = currentFleet.where((v) => v.category.toLowerCase() == 'sedan').length;
        final suvCount = currentFleet.where((v) => v.category.toLowerCase() == 'suv').length;
        final coupeCount = currentFleet.where((v) => v.category.toLowerCase() == 'coupe').length;

        double simulatedActiveRevenue = 0;
        for (var vehicle in currentFleet) {
          if (!vehicle.isAvailable) {
            simulatedActiveRevenue += vehicle.perDayCharges;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hello Shaaf & Anas', style: TextStyle(color: VeloceTheme.textSecondary, fontSize: 14)),
              const Text('Here\'s what\'s happening today', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              // ─── KPI row 1 ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Active Revenue',
                      value: '${(simulatedActiveRevenue / 1000).toStringAsFixed(1)}k PKR',
                      change: 'Live',
                      icon: Icons.trending_up,
                      color: VeloceTheme.successGreen,
                      isNeutral: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      title: 'Vehicles In Use',
                      value: '$inUseCount',
                      change: 'Active',
                      icon: Icons.confirmation_number_outlined,
                      color: VeloceTheme.accentBlueBright,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── KPI row 2: registered users + pending bookings (live) ──────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, userSnap) {
                  final userCount = userSnap.data?.docs.length ?? 0;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('bookings').where('status', isEqualTo: 'pending').snapshots(),
                    builder: (context, bookingSnap) {
                      final pendingCount = bookingSnap.data?.docs.length ?? 0;
                      return Row(
                        children: [
                          Expanded(child: _KpiCard(title: 'Registered Users', value: '$userCount', change: 'Total', icon: Icons.people_outline, color: const Color(0xFF8B5CF6), isNeutral: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _KpiCard(title: 'Pending Bookings', value: '$pendingCount', change: 'New', icon: Icons.notifications_active_outlined, color: VeloceTheme.accentGold)),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // ─── Booking Requests (live notification feed) ──────────────────
              const SectionHeader(title: 'Booking Requests'),
              const SizedBox(height: 14),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .orderBy('createdAt', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlueBright)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return GlassCard(
                      child: Column(
                        children: const [
                          Icon(Icons.inbox_outlined, color: VeloceTheme.textMuted, size: 36),
                          SizedBox(height: 10),
                          Text('No bookings yet', style: TextStyle(color: VeloceTheme.textSecondary, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('New booking requests will show up here.', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  final bookings = docs.map((d) => BookingRecord.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList();

                  return Column(
                    children: bookings.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BookingRequestTile(
                        booking: b,
                        onConfirm: () => _updateBookingStatus(context, b.id, 'confirmed'),
                        onCancel: () => _updateBookingStatus(context, b.id, 'cancelled'),
                      ),
                    )).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              const SectionHeader(title: 'Revenue Overview'),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Revenue Trend', style: TextStyle(color: VeloceTheme.textSecondary, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: VeloceTheme.bgElevated, borderRadius: BorderRadius.circular(6)),
                          child: const Text('2026', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => const FlLine(color: VeloceTheme.borderColor, strokeWidth: 0.5),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Text('${(v / 1000).toInt()}k', style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 9)),
                                reservedSize: 36,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
                                  if (v.toInt() < months.length) {
                                    return Text(months[v.toInt()], style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 9));
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 85000),
                                FlSpot(1, 92000),
                                FlSpot(2, 98000),
                                FlSpot(3, 105000),
                                FlSpot(4, 118000),
                                FlSpot(5, 132000),
                                FlSpot(6, 142800),
                              ],
                              isCurved: true,
                              color: VeloceTheme.accentBlueBright,
                              barWidth: 2.5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                                  radius: 4,
                                  color: VeloceTheme.accentBlueBright,
                                  strokeWidth: 2,
                                  strokeColor: VeloceTheme.bgDeep,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [VeloceTheme.accentBlue.withOpacity(0.3), VeloceTheme.accentBlue.withOpacity(0)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const SectionHeader(title: 'Fleet at a Glance'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _FleetStat(label: 'Total Vehicles', value: '$totalVehicles', color: VeloceTheme.accentBlueBright)),
                  const SizedBox(width: 12),
                  Expanded(child: _FleetStat(label: 'Available', value: '$availableCount', color: VeloceTheme.successGreen)),
                  const SizedBox(width: 12),
                  Expanded(child: _FleetStat(label: 'In Use', value: '$inUseCount', color: VeloceTheme.accentGold)),
                ],
              ),
              const SizedBox(height: 24),

              const SectionHeader(title: 'Category Breakdown'),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  children: [
                    _CategoryBar(label: 'Sports', count: sportsCount, total: totalVehicles, color: VeloceTheme.accentBlueBright),
                    const SizedBox(height: 12),
                    _CategoryBar(label: 'Sedans', count: sedanCount, total: totalVehicles, color: VeloceTheme.successGreen),
                    const SizedBox(height: 12),
                    _CategoryBar(label: 'SUVs', count: suvCount, total: totalVehicles, color: VeloceTheme.accentGold),
                    const SizedBox(height: 12),
                    _CategoryBar(label: 'Coupes', count: coupeCount, total: totalVehicles, color: const Color(0xFF8B5CF6)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _QuickAction(icon: Icons.add_circle_outline, label: 'Add Vehicle', color: VeloceTheme.accentBlueBright, onTap: () => onTabSelected(1)),
                  _QuickAction(icon: Icons.people_outline, label: 'View Users', color: VeloceTheme.successGreen, onTap: () => onTabSelected(2)),
                  _QuickAction(icon: Icons.directions_car, label: 'Manage Fleet', color: VeloceTheme.accentGold, onTap: () => onTabSelected(1)),
                  _QuickAction(icon: Icons.bar_chart, label: 'Export Report', color: const Color(0xFF8B5CF6), onTap: () => _simulateExportReport(context)),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ─── Booking Request Tile (the "notification" UI) ─────────────────────────────
class _BookingRequestTile extends StatelessWidget {
  final BookingRecord booking;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _BookingRequestTile({required this.booking, required this.onConfirm, required this.onCancel});

  Color _statusColor() {
    switch (booking.status) {
      case BookingStatus.pending:
        return VeloceTheme.accentGold;
      case BookingStatus.confirmed:
        return VeloceTheme.successGreen;
      case BookingStatus.completed:
        return VeloceTheme.textMuted;
      case BookingStatus.cancelled:
        return VeloceTheme.accentRed;
    }
  }

  String _dateLabel() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = booking.pickupDate;
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: booking.status == BookingStatus.pending ? VeloceTheme.accentGold.withOpacity(0.4) : VeloceTheme.borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  booking.vehicleImageUrl,
                  width: 60,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 46,
                    color: VeloceTheme.bgElevated,
                    child: const Icon(Icons.directions_car, color: VeloceTheme.textMuted, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${booking.vehicleBrand} ${booking.vehicleName}', style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('${booking.userName} · ${booking.userEmail}', style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _statusColor().withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(booking.status.label, style: TextStyle(color: _statusColor(), fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: VeloceTheme.borderColor, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: VeloceTheme.textMuted, size: 13),
              const SizedBox(width: 5),
              Text(_dateLabel(), style: const TextStyle(color: VeloceTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.access_time, color: VeloceTheme.textMuted, size: 13),
              const SizedBox(width: 5),
              Text(booking.timeSlot, style: const TextStyle(color: VeloceTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.location_on_outlined, color: VeloceTheme.textMuted, size: 13),
              const SizedBox(width: 5),
              Expanded(child: Text(booking.location, style: const TextStyle(color: VeloceTheme.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (booking.status == BookingStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: VeloceTheme.accentRed),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onCancel,
                    child: const Text('Decline', style: TextStyle(color: VeloceTheme.accentRed, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VeloceTheme.successGreen,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onConfirm,
                    child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  final bool isNeutral;

  const _KpiCard({required this.title, required this.value, required this.change, required this.icon, required this.color, this.isNeutral = false});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isNeutral ? VeloceTheme.bgElevated : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(change, style: TextStyle(color: isNeutral ? VeloceTheme.textMuted : color, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FleetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FleetStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: VeloceTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _CategoryBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final double calculatedProgress = total > 0 ? (count / total) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: VeloceTheme.textSecondary, fontSize: 13)),
            Text('$count vehicles', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: calculatedProgress,
            backgroundColor: VeloceTheme.bgElevated,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: VeloceTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}




class _VeloceLogo extends StatelessWidget {
  const _VeloceLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/veloce.png',
        height: 55,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─── Account Drawer ───────────────────────────────────────────────────────────
/// Slides in from the right when the avatar in the top app bar is tapped.
/// Shows a larger version of the same initial-letter avatar, the signed-in
/// user's email, and a Logout button that signs out of Firebase and sends
/// the user back to the login screen.
class _AccountDrawer extends StatelessWidget {
  const _AccountDrawer();

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? 'Guest';
    final String initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';

    return Drawer(
      backgroundColor: VeloceTheme.bgDeep,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VeloceTheme.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VeloceTheme.borderColor),
                    ),
                    child: const Icon(Icons.close, color: VeloceTheme.textSecondary, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Large avatar ────────────────────────────────────────────
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VeloceTheme.bgCard,
                    border: Border.all(
                      color: VeloceTheme.accentBlueBright.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VeloceTheme.accentBlueBright.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: VeloceTheme.accentBlueBright,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ─── Email ────────────────────────────────────────────────────
              Center(
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: VeloceTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Spacer(),

              // ─── Logout button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: VeloceButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  color: VeloceTheme.accentRed,
                  onPressed: () => _logout(context),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}