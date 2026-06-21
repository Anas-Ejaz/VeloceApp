import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../AppTheme.dart';
import '../../models.dart';
import '../../commonWidgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Live stream of every account that has actually signed up through the app.
  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppUser> _applySearch(List<AppUser> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
  }

  void _showUserDetail(AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeloceTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UserDetailSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloceTheme.bgDeep,
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (context, snapshot) {
          final allUsers = (snapshot.data?.docs ?? [])
              .map((doc) => AppUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          final users = _applySearch(allUsers);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User Management', style: TextStyle(color: VeloceTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${allUsers.length} registered user${allUsers.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      style: const TextStyle(color: VeloceTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search name or email...',
                        prefixIcon: Icon(Icons.search, color: VeloceTheme.textMuted, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Expanded(child: Center(child: CircularProgressIndicator(color: VeloceTheme.accentBlueBright)))
              else if (allUsers.isEmpty)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 56, color: VeloceTheme.textMuted),
                          SizedBox(height: 14),
                          Text('No users yet', style: TextStyle(color: VeloceTheme.textSecondary, fontSize: 15)),
                          SizedBox(height: 6),
                          Text(
                            'Accounts will appear here as soon as people sign up in the app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: VeloceTheme.textMuted, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (users.isEmpty)
                  const Expanded(child: Center(child: Text('No users found', style: TextStyle(color: VeloceTheme.textMuted))))
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (ctx, i) => _UserTile(
                        user: users[i],
                        onTap: () => _showUserDetail(users[i]),
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

// ─── User Tile ────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  String _initial() => user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

  String _joinedLabel() {
    if (user.createdAt == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = user.createdAt!;
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VeloceTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VeloceTheme.borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: VeloceTheme.accentBlue.withOpacity(0.15),
              child: Text(_initial(), style: const TextStyle(color: VeloceTheme.accentBlueBright, fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(user.email, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.chevron_right, color: VeloceTheme.textMuted, size: 18),
                const SizedBox(height: 4),
                Text(_joinedLabel(), style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User Detail Sheet ────────────────────────────────────────────────────────
class _UserDetailSheet extends StatelessWidget {
  final AppUser user;
  const _UserDetailSheet({required this.user});

  String _joinedLabel() {
    if (user.createdAt == null) return 'Unknown';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = user.createdAt!;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VeloceTheme.textMuted, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 36,
            backgroundColor: VeloceTheme.accentBlue.withOpacity(0.15),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(color: VeloceTheme.accentBlueBright, fontWeight: FontWeight.w800, fontSize: 28),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.name, style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(user.email, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              children: [
                _DetailRow('User ID', user.id),
                const Divider(color: VeloceTheme.borderColor, height: 16),
                _DetailRow('Joined', _joinedLabel()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: VeloceButton(label: 'Close', onPressed: () => Navigator.pop(context), isOutlined: true),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: VeloceTheme.textMuted, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: VeloceTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}