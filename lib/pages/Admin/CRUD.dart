// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../AppTheme.dart';
// import '../../models.dart';
// import '../../commonWidgets.dart';
//
// class AdminFleetScreen extends StatefulWidget {
//   const AdminFleetScreen({super.key});
//
//   @override
//   State<AdminFleetScreen> createState() => _AdminFleetScreenState();
// }
//
// class _AdminFleetScreenState extends State<AdminFleetScreen> {
//   String _filter = 'All';
//   final List<String> _categories = ['All', 'Sports', 'Sedan', 'SUV', 'Coupe', 'Truck'];
//
//   final Stream<QuerySnapshot> _fleetStream = FirebaseFirestore.instance
//       .collection('vehicles')
//       .orderBy('brand')
//       .snapshots();
//
//   void _showAddVehicleSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: VeloceTheme.bgCard,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (_) => const _AddVehicleSheet(),
//     );
//   }
//
//   void _showEditVehicleSheet(Vehicle v) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: VeloceTheme.bgCard,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (_) => _AddVehicleSheet(vehicle: v),
//     );
//   }
//
//   void _showVehicleOptions(Vehicle v) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: VeloceTheme.bgCard,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (_) => Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(width: 40, height: 4, decoration: BoxDecoration(color: VeloceTheme.textMuted, borderRadius: BorderRadius.circular(2))),
//             const SizedBox(height: 20),
//             Text(v.name, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
//             const SizedBox(height: 20),
//             _OptionTile(
//               icon: Icons.edit_outlined,
//               label: 'Edit Vehicle Details',
//               color: VeloceTheme.accentBlueBright,
//               onTap: () {
//                 Navigator.pop(context);
//                 _showEditVehicleSheet(v);
//               },
//             ),
//             _OptionTile(
//               icon: Icons.swap_horiz,
//               label: 'Toggle Availability',
//               color: VeloceTheme.accentGold,
//               onTap: () async {
//                 Navigator.pop(context);
//                 try {
//                   await FirebaseFirestore.instance
//                       .collection('vehicles')
//                       .doc(v.id)
//                       .update({'isAvailable': !v.isAvailable});
//                 } catch (e) {
//                   debugPrint("Failed to toggle availability: $e");
//                 }
//               },
//             ),
//             _OptionTile(icon: Icons.bar_chart, label: 'View Analytics', color: VeloceTheme.successGreen, onTap: () { Navigator.pop(context); }),
//             _OptionTile(icon: Icons.delete_outline, label: 'Remove Vehicle', color: VeloceTheme.accentRed, onTap: () {
//               Navigator.pop(context);
//               _showDeleteConfirm(v);
//             }),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showDeleteConfirm(Vehicle v) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         backgroundColor: VeloceTheme.bgCard,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text('Remove Vehicle?', style: TextStyle(color: VeloceTheme.textPrimary, fontWeight: FontWeight.w700)),
//         content: Text('Are you sure you want to remove ${v.name} from the fleet?', style: const TextStyle(color: VeloceTheme.textSecondary, height: 1.5)),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('Cancel', style: TextStyle(color: VeloceTheme.textMuted)),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(dialogContext);
//               try {
//                 await FirebaseFirestore.instance
//                     .collection('vehicles')
//                     .doc(v.id)
//                     .delete();
//
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('${v.name} successfully removed.')),
//                   );
//                 }
//               } catch (e) {
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Database Deletion Failure: $e')),
//                   );
//                 }
//               }
//             },
//             child: const Text('Remove', style: TextStyle(color: VeloceTheme.accentRed, fontWeight: FontWeight.w700)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: VeloceTheme.bgDeep,
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _showAddVehicleSheet,
//         backgroundColor: VeloceTheme.accentBlue,
//         icon: const Icon(Icons.add, color: Colors.white),
//         label: const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _fleetStream,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlue));
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Database Error: ${snapshot.error}', style: const TextStyle(color: VeloceTheme.accentRed)));
//           }
//
//           final docs = snapshot.data?.docs ?? [];
//           final allVehicles = docs.map((doc) {
//             return Vehicle.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
//           }).toList();
//
//           final displayedVehicles = _filter == 'All'
//               ? allVehicles
//               : allVehicles.where((v) => v.category == _filter).toList();
//
//           final availableCount = allVehicles.where((v) => v.isAvailable).length;
//           final inUseCount = allVehicles.where((v) => !v.isAvailable).length;
//
//           return Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('Fleet Management', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
//                     const SizedBox(height: 4),
//                     Text('${displayedVehicles.length} vehicles matching layout', style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
//                     const SizedBox(height: 14),
//
//                     Row(
//                       children: [
//                         _MiniStat(label: 'Available', value: '$availableCount', color: VeloceTheme.successGreen),
//                         const SizedBox(width: 10),
//                         _MiniStat(label: 'In Use', value: '$inUseCount', color: VeloceTheme.accentRed),
//                         const SizedBox(width: 10),
//                         _MiniStat(label: 'Total', value: '${allVehicles.length}', color: VeloceTheme.accentBlueBright),
//                       ],
//                     ),
//                     const SizedBox(height: 14),
//
//                     SizedBox(
//                       height: 36,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: _categories.length,
//                         itemBuilder: (ctx, i) {
//                           final cat = _categories[i];
//                           final sel = cat == _filter;
//                           return GestureDetector(
//                             onTap: () => setState(() => _filter = cat),
//                             child: AnimatedContainer(
//                               duration: const Duration(milliseconds: 200),
//                               margin: const EdgeInsets.only(right: 8),
//                               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
//                               decoration: BoxDecoration(
//                                 color: sel ? VeloceTheme.accentBlue : VeloceTheme.bgCard,
//                                 borderRadius: BorderRadius.circular(18),
//                                 border: Border.all(color: sel ? VeloceTheme.accentBlue : VeloceTheme.borderColor),
//                               ),
//                               child: Text(cat, style: TextStyle(color: sel ? Colors.white : VeloceTheme.textMuted, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               Expanded(
//                 child: displayedVehicles.isEmpty
//                     ? Center(child: Text('No vehicles found in $_filter', style: const TextStyle(color: VeloceTheme.textMuted)))
//                     : ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: displayedVehicles.length,
//                   itemBuilder: (ctx, i) => _AdminVehicleTile(
//                     vehicle: displayedVehicles[i],
//                     onTap: () => _showVehicleOptions(displayedVehicles[i]),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _AdminVehicleTile extends StatelessWidget {
//   final Vehicle vehicle;
//   final VoidCallback onTap;
//
//   const _AdminVehicleTile({required this.vehicle, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: VeloceTheme.bgCard,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: VeloceTheme.borderColor),
//         ),
//         child: Row(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: Image.network(
//                 vehicle.imageUrl, width: 80, height: 60, fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => Container(width: 80, height: 60, color: VeloceTheme.bgElevated, child: const Icon(Icons.directions_car, color: VeloceTheme.textMuted)),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text('${vehicle.brand} ${vehicle.name}', style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
//                       ),
//                       Container(
//                         width: 8, height: 8,
//                         decoration: BoxDecoration(
//                           color: vehicle.isAvailable ? VeloceTheme.successGreen : VeloceTheme.accentRed,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 3),
//                   Text('${vehicle.category} · ${vehicle.year} · ${vehicle.color}', style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 12)),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       _SpecTag('${vehicle.horsepower.toInt()} HP'),
//                       const SizedBox(width: 4),
//                       _SpecTag('${vehicle.zeroToSixty}s 0-60'),
//                       const Spacer(),
//                       // FIXED OVERFLOW: Wrapped clean dynamic layout formatting safely
//                       Flexible(
//                         child: FittedBox(
//                           fit: BoxFit.scaleDown,
//                           child: Text(
//                             'Rs.${vehicle.perDayCharges.toInt()}/mo',
//                             style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             const Icon(Icons.more_vert, color: VeloceTheme.textMuted, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _SpecTag extends StatelessWidget {
//   final String text;
//   const _SpecTag(this.text);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//       decoration: BoxDecoration(color: VeloceTheme.bgElevated, borderRadius: BorderRadius.circular(5), border: Border.all(color: VeloceTheme.borderColor)),
//       child: Text(text, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 10)),
//     );
//   }
// }
//
// class _MiniStat extends StatelessWidget {
//   final String label;
//   final String value;
//   final Color color;
//
//   const _MiniStat({required this.label, required this.value, required this.color});
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Column(
//           children: [
//             Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
//             Text(label, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 11)),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _OptionTile extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;
//
//   const _OptionTile({required this.icon, required this.label, required this.color, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
//               child: Icon(icon, color: color, size: 18),
//             ),
//             const SizedBox(width: 14),
//             Text(label, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─── COMPLETE ADMIN CONTROLS SHEET: Matches Firestore Fields Natively ───────
// class _AddVehicleSheet extends StatefulWidget {
//   final Vehicle? vehicle;
//   const _AddVehicleSheet({this.vehicle});
//
//   @override
//   State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
// }
//
// class _AddVehicleSheetState extends State<_AddVehicleSheet> {
//   final _brandCtrl = TextEditingController();
//   final _nameCtrl = TextEditingController();
//   final _monthlyPriceCtrl = TextEditingController();
//   final _perDayChargesCtrl = TextEditingController();
//   final _hpCtrl = TextEditingController();
//   final _colorCtrl = TextEditingController();
//   final _yearCtrl = TextEditingController();
//   final _zeroToSixtyCtrl = TextEditingController();
//   final _imageUrlCtrl = TextEditingController();
//   final _descriptionCtrl = TextEditingController();
//
//   String _selectedCategory = 'Sedan';
//   bool _isSaving = false;
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.vehicle != null) {
//       _brandCtrl.text = widget.vehicle!.brand;
//       _nameCtrl.text = widget.vehicle!.name;
//       _monthlyPriceCtrl.text = widget.vehicle!.perDayCharges.toInt().toString();
//       _perDayChargesCtrl.text = widget.vehicle!.perDayCharges.toInt().toString();
//       _hpCtrl.text = widget.vehicle!.horsepower.toInt().toString();
//       _colorCtrl.text = widget.vehicle!.color;
//       _yearCtrl.text = widget.vehicle!.year.toString();
//       _zeroToSixtyCtrl.text = widget.vehicle!.zeroToSixty.toString();
//       _imageUrlCtrl.text = widget.vehicle!.imageUrl;
//       _descriptionCtrl.text = widget.vehicle!.description;
//       _selectedCategory = widget.vehicle!.category;
//     } else {
//       _yearCtrl.text = "2026"; // Default standard seeding value
//       _zeroToSixtyCtrl.text = "4.0";
//     }
//   }
//
//   @override
//   void dispose() {
//     _brandCtrl.dispose();
//     _nameCtrl.dispose();
//     _monthlyPriceCtrl.dispose();
//     _perDayChargesCtrl.dispose();
//     _hpCtrl.dispose();
//     _colorCtrl.dispose();
//     _yearCtrl.dispose();
//     _zeroToSixtyCtrl.dispose();
//     _imageUrlCtrl.dispose();
//     _descriptionCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _submitVehicle() async {
//     final brand = _brandCtrl.text.trim();
//     final name = _nameCtrl.text.trim();
//     final imgUrl = _imageUrlCtrl.text.trim();
//
//     if (brand.isEmpty || name.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Brand and Model Name fields are mandatory.')),
//       );
//       return;
//     }
//
//     setState(() => _isSaving = true);
//
//     final dataMap = {
//       'brand': brand,
//       'name': name,
//       'category': _selectedCategory,
//       'color': _colorCtrl.text.trim().isEmpty ? 'Black' : _colorCtrl.text.trim(),
//       'description': _descriptionCtrl.text.trim().isEmpty ? 'No description provided.' : _descriptionCtrl.text.trim(),
//       'horsepower': double.tryParse(_hpCtrl.text.trim()) ?? 150.0,
//       'zeroToSixty': double.tryParse(_zeroToSixtyCtrl.text.trim()) ?? 4.0,
//       'monthlyPrice': double.tryParse(_monthlyPriceCtrl.text.trim()) ?? 0.0,
//       'perDayCharges': double.tryParse(_perDayChargesCtrl.text.trim()) ?? 0.0,
//       'year': int.tryParse(_yearCtrl.text.trim()) ?? 2026,
//       'imageUrl': imgUrl.isEmpty ? 'https://images.unsplash.com/photo-1614162692292-7ac56d7f7f1e?w=800' : imgUrl,
//       'isAvailable': widget.vehicle?.isAvailable ?? true,
//       'features': widget.vehicle?.features ?? ['Premium Sound', 'Sport Packages'],
//       'rating': widget.vehicle?.rating ?? 5.0,
//       'reviewCount': widget.vehicle?.reviewCount ?? 0,
//     };
//
//     try {
//       if (widget.vehicle != null) {
//         await FirebaseFirestore.instance.collection('vehicles').doc(widget.vehicle!.id).update(dataMap);
//       } else {
//         await FirebaseFirestore.instance.collection('vehicles').add(dataMap);
//       }
//       if (mounted) Navigator.pop(context);
//     } catch (e) {
//       setState(() => _isSaving = false);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firestore Save Failure: $e')));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isEditMode = widget.vehicle != null;
//
//     return Padding(
//       padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
//       child: SizedBox(
//         height: MediaQuery.of(context).size.height * 0.75, // Keeps bottom sheet neat and clear
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VeloceTheme.textMuted, borderRadius: BorderRadius.circular(2)))),
//               const SizedBox(height: 20),
//               Text(isEditMode ? 'Modify Vehicle Profile' : 'Register Vehicle to Fleet', style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
//               const SizedBox(height: 20),
//
//               Row(children: [
//                 Expanded(child: _FormField(ctrl: _brandCtrl, label: 'Brand', hint: 'e.g. Toyota')),
//                 const SizedBox(width: 12),
//                 Expanded(child: _FormField(ctrl: _nameCtrl, label: 'Model Name', hint: 'e.g. Land Cruiser')),
//               ]),
//               const SizedBox(height: 12),
//
//               Row(children: [
//                 Expanded(child: _FormField(ctrl: _monthlyPriceCtrl, label: 'Monthly Price (PKR)', hint: '40000', keyboardType: TextInputType.number)),
//                 const SizedBox(width: 12),
//                 Expanded(child: _FormField(ctrl: _perDayChargesCtrl, label: 'Daily Price (PKR)', hint: '2500', keyboardType: TextInputType.number)),
//               ]),
//               const SizedBox(height: 12),
//
//               Row(children: [
//                 Expanded(child: _FormField(ctrl: _hpCtrl, label: 'Horsepower', hint: '200', keyboardType: TextInputType.number)),
//                 const SizedBox(width: 12),
//                 Expanded(child: _FormField(ctrl: _zeroToSixtyCtrl, label: '0-60 mph (sec)', hint: '5.2', keyboardType: TextInputType.number)),
//               ]),
//               const SizedBox(height: 12),
//
//               Row(children: [
//                 Expanded(child: _FormField(ctrl: _colorCtrl, label: 'Color Variant', hint: 'e.g. Arctic White')),
//                 const SizedBox(width: 12),
//                 Expanded(child: _FormField(ctrl: _yearCtrl, label: 'Production Year', hint: '2026', keyboardType: TextInputType.number)),
//               ]),
//               const SizedBox(height: 12),
//
//               _FormField(ctrl: _imageUrlCtrl, label: 'Vehicle Image CDN URL', hint: 'https://images.unsplash.com/...'),
//               const SizedBox(height: 12),
//
//               _FormField(ctrl: _descriptionCtrl, label: 'Administrative Fleet Overview', hint: 'Enter premium features or condition descriptions...'),
//               const SizedBox(height: 16),
//
//               const Text('Category Classification', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: ['Sports', 'Sedan', 'SUV', 'Coupe', 'Truck'].map((c) {
//                   final isSelected = _selectedCategory == c;
//                   return GestureDetector(
//                     onTap: () => setState(() => _selectedCategory = c),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isSelected ? VeloceTheme.accentBlue : VeloceTheme.bgElevated,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: isSelected ? VeloceTheme.accentBlue : VeloceTheme.borderColor),
//                       ),
//                       child: Text(c, style: TextStyle(color: isSelected ? Colors.white : VeloceTheme.textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
//                     ),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 24),
//
//               SizedBox(
//                 width: double.infinity,
//                 child: _isSaving
//                     ? const Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlue))
//                     : VeloceButton(
//                   label: isEditMode ? 'Commit Changes' : 'Append to Active Fleet',
//                   onPressed: _submitVehicle,
//                   icon: isEditMode ? Icons.check_circle_outline : Icons.add_circle_outline,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _FormField extends StatelessWidget {
//   final TextEditingController ctrl;
//   final String label;
//   final String hint;
//   final TextInputType keyboardType;
//
//   const _FormField({required this.ctrl, required this.label, required this.hint, this.keyboardType = TextInputType.text});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
//         const SizedBox(height: 6),
//         TextField(
//           controller: ctrl,
//           keyboardType: keyboardType,
//           style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 14),
//           decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
//         ),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../AppTheme.dart';
import '../../models.dart';
import '../../commonWidgets.dart';
import '../../database_helper.dart'; // 👈 Sqflite helper import kiya gaya

class AdminFleetScreen extends StatefulWidget {
  const AdminFleetScreen({super.key});

  @override
  State<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends State<AdminFleetScreen> {
  String _filter = 'All';
  final List<String> _categories = ['All', 'Sports', 'Sedan', 'SUV', 'Coupe', 'Truck'];

  final Stream<QuerySnapshot> _fleetStream = FirebaseFirestore.instance
      .collection('vehicles')
      .orderBy('brand')
      .snapshots();

  void _showAddVehicleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeloceTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddVehicleSheet(),
    );
  }

  void _showEditVehicleSheet(Vehicle v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeloceTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddVehicleSheet(vehicle: v),
    );
  }

  void _showVehicleOptions(Vehicle v) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VeloceTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: VeloceTheme.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(v.name, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _OptionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Vehicle Details',
              color: VeloceTheme.accentBlueBright,
              onTap: () {
                Navigator.pop(context);
                _showEditVehicleSheet(v);
              },
            ),
            _OptionTile(
              icon: Icons.swap_horiz,
              label: 'Toggle Availability',
              color: VeloceTheme.accentGold,
              onTap: () async {
                Navigator.pop(context);
                try {
                  bool newStatus = !v.isAvailable;

                  // 1. Firebase Update
                  await FirebaseFirestore.instance
                      .collection('vehicles')
                      .doc(v.id)
                      .update({'isAvailable': newStatus});

                  // 2. Sqflite Database Update
                  final updatedVehicle = Vehicle(
                    id: v.id, name: v.name, brand: v.brand, category: v.category,
                    horsepower: v.horsepower, zeroToSixty: v.zeroToSixty, perDayCharges: v.perDayCharges,
                    imageUrl: v.imageUrl, description: v.description, isAvailable: newStatus,
                    features: v.features, rating: v.rating, reviewCount: v.reviewCount, color: v.color, year: v.year,
                  );
                  await DatabaseHelper.instance.insertOrUpdateLocal(updatedVehicle);

                } catch (e) {
                  debugPrint("Failed to toggle availability: $e");
                }
              },
            ),
            _OptionTile(icon: Icons.bar_chart, label: 'View Analytics', color: VeloceTheme.successGreen, onTap: () { Navigator.pop(context); }),
            _OptionTile(icon: Icons.delete_outline, label: 'Remove Vehicle', color: VeloceTheme.accentRed, onTap: () {
              Navigator.pop(context);
              _showDeleteConfirm(v);
            }),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(Vehicle v) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VeloceTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Vehicle?', style: TextStyle(color: VeloceTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove ${v.name} from the fleet?', style: const TextStyle(color: VeloceTheme.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: VeloceTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                // 1. Firebase Delete
                await FirebaseFirestore.instance
                    .collection('vehicles')
                    .doc(v.id)
                    .delete();

                // 2. Sqflite Delete
                await DatabaseHelper.instance.deleteLocal(v.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${v.name} successfully removed.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Database Deletion Failure: $e')),
                  );
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: VeloceTheme.accentRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVehicleSheet,
        backgroundColor: VeloceTheme.accentBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fleetStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Database Error: ${snapshot.error}', style: const TextStyle(color: VeloceTheme.accentRed)));
          }

          final docs = snapshot.data?.docs ?? [];
          final allVehicles = docs.map((doc) {
            return Vehicle.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          // BONUS SYNC: Jab bhi data cloud se fetch hoga, ye unhe silently Sqflite me cache kar lega.
          for (var vehicle in allVehicles) {
            DatabaseHelper.instance.insertOrUpdateLocal(vehicle);
          }

          final displayedVehicles = _filter == 'All'
              ? allVehicles
              : allVehicles.where((v) => v.category == _filter).toList();

          final availableCount = allVehicles.where((v) => v.isAvailable).length;
          final inUseCount = allVehicles.where((v) => !v.isAvailable).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fleet Management', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${displayedVehicles.length} vehicles matching layout', style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        _MiniStat(label: 'Available', value: '$availableCount', color: VeloceTheme.successGreen),
                        const SizedBox(width: 10),
                        _MiniStat(label: 'In Use', value: '$inUseCount', color: VeloceTheme.accentRed),
                        const SizedBox(width: 10),
                        _MiniStat(label: 'Total', value: '${allVehicles.length}', color: VeloceTheme.accentBlueBright),
                      ],
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (ctx, i) {
                          final cat = _categories[i];
                          final sel = cat == _filter;
                          return GestureDetector(
                            onTap: () => setState(() => _filter = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: sel ? VeloceTheme.accentBlue : VeloceTheme.bgCard,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: sel ? VeloceTheme.accentBlue : VeloceTheme.borderColor),
                              ),
                              child: Text(cat, style: TextStyle(color: sel ? Colors.white : VeloceTheme.textMuted, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: displayedVehicles.isEmpty
                    ? Center(child: Text('No vehicles found in $_filter', style: const TextStyle(color: VeloceTheme.textMuted)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayedVehicles.length,
                  itemBuilder: (ctx, i) => _AdminVehicleTile(
                    vehicle: displayedVehicles[i],
                    onTap: () => _showVehicleOptions(displayedVehicles[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminVehicleTile extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _AdminVehicleTile({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VeloceTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VeloceTheme.borderColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                vehicle.imageUrl, width: 80, height: 60, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 80, height: 60, color: VeloceTheme.bgElevated, child: const Icon(Icons.directions_car, color: VeloceTheme.textMuted)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${vehicle.brand} ${vehicle.name}', style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: vehicle.isAvailable ? VeloceTheme.successGreen : VeloceTheme.accentRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${vehicle.category} · ${vehicle.year} · ${vehicle.color}', style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _SpecTag('${vehicle.horsepower.toInt()} HP'),
                      const SizedBox(width: 4),
                      _SpecTag('${vehicle.zeroToSixty}s 0-60'),
                      const Spacer(),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Rs.${vehicle.perDayCharges.toInt()}/mo',
                            style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert, color: VeloceTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SpecTag extends StatelessWidget {
  final String text;
  const _SpecTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: VeloceTheme.bgElevated, borderRadius: BorderRadius.circular(5), border: Border.all(color: VeloceTheme.borderColor)),
      child: Text(text, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 10)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _AddVehicleSheet extends StatefulWidget {
  final Vehicle? vehicle;
  const _AddVehicleSheet({this.vehicle});

  @override
  State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<_AddVehicleSheet> {
  final _brandCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _monthlyPriceCtrl = TextEditingController();
  final _perDayChargesCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _zeroToSixtyCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _selectedCategory = 'Sedan';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _brandCtrl.text = widget.vehicle!.brand;
      _nameCtrl.text = widget.vehicle!.name;
      _monthlyPriceCtrl.text = widget.vehicle!.perDayCharges.toInt().toString();
      _perDayChargesCtrl.text = widget.vehicle!.perDayCharges.toInt().toString();
      _hpCtrl.text = widget.vehicle!.horsepower.toInt().toString();
      _colorCtrl.text = widget.vehicle!.color;
      _yearCtrl.text = widget.vehicle!.year.toString();
      _zeroToSixtyCtrl.text = widget.vehicle!.zeroToSixty.toString();
      _imageUrlCtrl.text = widget.vehicle!.imageUrl;
      _descriptionCtrl.text = widget.vehicle!.description;
      _selectedCategory = widget.vehicle!.category;
    } else {
      _yearCtrl.text = "2026";
      _zeroToSixtyCtrl.text = "4.0";
    }
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _nameCtrl.dispose();
    _monthlyPriceCtrl.dispose();
    _perDayChargesCtrl.dispose();
    _hpCtrl.dispose();
    _colorCtrl.dispose();
    _yearCtrl.dispose();
    _zeroToSixtyCtrl.dispose();
    _imageUrlCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    final brand = _brandCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final imgUrl = _imageUrlCtrl.text.trim();

    if (brand.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand and Model Name fields are mandatory.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final dataMap = {
      'brand': brand,
      'name': name,
      'category': _selectedCategory,
      'color': _colorCtrl.text.trim().isEmpty ? 'Black' : _colorCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim().isEmpty ? 'No description provided.' : _descriptionCtrl.text.trim(),
      'horsepower': double.tryParse(_hpCtrl.text.trim()) ?? 150.0,
      'zeroToSixty': double.tryParse(_zeroToSixtyCtrl.text.trim()) ?? 4.0,
      'monthlyPrice': double.tryParse(_monthlyPriceCtrl.text.trim()) ?? 0.0,
      'perDayCharges': double.tryParse(_perDayChargesCtrl.text.trim()) ?? 0.0,
      'year': int.tryParse(_yearCtrl.text.trim()) ?? 2026,
      'imageUrl': imgUrl.isEmpty ? 'https://images.unsplash.com/photo-1614162692292-7ac56d7f7f1e?w=800' : imgUrl,
      'isAvailable': widget.vehicle?.isAvailable ?? true,
      'features': widget.vehicle?.features ?? ['Premium Sound', 'Sport Packages'],
      'rating': widget.vehicle?.rating ?? 5.0,
      'reviewCount': widget.vehicle?.reviewCount ?? 0,
    };

    try {
      String docId = widget.vehicle?.id ?? '';

      if (widget.vehicle != null) {
        // Edit Mode: Firebase Update
        await FirebaseFirestore.instance.collection('vehicles').doc(docId).update(dataMap);
      } else {
        // Add Mode: Firebase Add
        DocumentReference docRef = await FirebaseFirestore.instance.collection('vehicles').add(dataMap);
        docId = docRef.id;
      }

      // ─── SQFLITE MIRROR: Sync local data with new/updated data ───
      final localVehicle = Vehicle(
        id: docId,
        brand: dataMap['brand'] as String,
        name: dataMap['name'] as String,
        category: dataMap['category'] as String,
        color: dataMap['color'] as String,
        description: dataMap['description'] as String,
        horsepower: dataMap['horsepower'] as double,
        zeroToSixty: dataMap['zeroToSixty'] as double,
        perDayCharges: dataMap['perDayCharges'] as double,
        year: dataMap['year'] as int,
        imageUrl: dataMap['imageUrl'] as String,
        isAvailable: dataMap['isAvailable'] as bool,
        features: dataMap['features'] as List<String>,
        rating: dataMap['rating'] as double,
        reviewCount: dataMap['reviewCount'] as int,
      );
      await DatabaseHelper.instance.insertOrUpdateLocal(localVehicle);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firestore/Sqflite Save Failure: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.vehicle != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VeloceTheme.textMuted, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(isEditMode ? 'Modify Vehicle Profile' : 'Register Vehicle to Fleet', style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),

              Row(children: [
                Expanded(child: _FormField(ctrl: _brandCtrl, label: 'Brand', hint: 'e.g. Toyota')),
                const SizedBox(width: 12),
                Expanded(child: _FormField(ctrl: _nameCtrl, label: 'Model Name', hint: 'e.g. Land Cruiser')),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: _FormField(ctrl: _monthlyPriceCtrl, label: 'Monthly Price (PKR)', hint: '40000', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _FormField(ctrl: _perDayChargesCtrl, label: 'Daily Price (PKR)', hint: '2500', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: _FormField(ctrl: _hpCtrl, label: 'Horsepower', hint: '200', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _FormField(ctrl: _zeroToSixtyCtrl, label: '0-60 mph (sec)', hint: '5.2', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: _FormField(ctrl: _colorCtrl, label: 'Color Variant', hint: 'e.g. Arctic White')),
                const SizedBox(width: 12),
                Expanded(child: _FormField(ctrl: _yearCtrl, label: 'Production Year', hint: '2026', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),

              _FormField(ctrl: _imageUrlCtrl, label: 'Vehicle Image CDN URL', hint: 'https://images.unsplash.com/...'),
              const SizedBox(height: 12),

              _FormField(ctrl: _descriptionCtrl, label: 'Administrative Fleet Overview', hint: 'Enter premium features or condition descriptions...'),
              const SizedBox(height: 16),

              const Text('Category Classification', style: TextStyle(color: VeloceTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Sports', 'Sedan', 'SUV', 'Coupe', 'Truck'].map((c) {
                  final isSelected = _selectedCategory == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? VeloceTheme.accentBlue : VeloceTheme.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? VeloceTheme.accentBlue : VeloceTheme.borderColor),
                      ),
                      child: Text(c, style: TextStyle(color: isSelected ? Colors.white : VeloceTheme.textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: _isSaving
                    ? const Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlue))
                    : VeloceButton(
                  label: isEditMode ? 'Commit Changes' : 'Append to Active Fleet',
                  onPressed: _submitVehicle,
                  icon: isEditMode ? Icons.check_circle_outline : Icons.add_circle_outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _FormField({required this.ctrl, required this.label, required this.hint, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        ),
      ],
    );
  }
}