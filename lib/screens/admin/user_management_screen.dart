import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Aktif', 'Nonaktif', 'Admin'];

  List<UserModel> _filterUsers(List<UserModel> allUsers) {
    final query = _searchController.text.toLowerCase();
    return allUsers.where((u) {
      final matchSearch = query.isEmpty ||
          u.fullName.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
      final matchFilter = _selectedFilter == 'Semua' ||
          (_selectedFilter == 'Aktif' && u.isActive) ||
          (_selectedFilter == 'Nonaktif' && !u.isActive) ||
          (_selectedFilter == 'Admin' && u.role == 'admin');
      return matchSearch && matchFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text('Terjadi kesalahan', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)));
          }

          final allUsers = snapshot.data!.docs
              .map((doc) => UserModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          final filteredUsers = _filterUsers(allUsers);

          return Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 8),
              _buildFilterChips(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${filteredUsers.length} pengguna ditemukan',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildUserList(filteredUsers)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComingSoon('Tambah User'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: Text('Tambah User', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Kelola User', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cari nama atau email...',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _filters[index] == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2D5016) : const Color(0xFFE8EDE3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_filters[index], style: GoogleFonts.poppins(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? Colors.white : Colors.grey[700])),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Tidak ada pengguna', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _UserCard(
          user: user,
          onEdit: () => _showUserForm(context, user),
          onDelete: () => _confirmDelete(user),
          onToggleStatus: () => _toggleUserStatus(user),
        );
      },
    );
  }

  void _showUserForm(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UserFormSheet(
        user: user,
        onSave: (data) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          try {
            if (user != null) {
              await _userService.updateUser(
                id: user.id,
                fullName: data['name'],
                phone: data['phone'],
                role: data['role']?.toLowerCase(),
              );
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('${data['name']} berhasil diperbarui', style: GoogleFonts.poppins(fontSize: 13)),
                  backgroundColor: const Color(0xFF2D5016),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          } catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan: $e', style: GoogleFonts.poppins(fontSize: 13)),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
  }

  void _toggleUserStatus(UserModel user) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _userService.toggleUserStatus(user.id, !user.isActive);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Status ${user.fullName} diubah', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFF2D5016),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus User', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
        content: Text('Yakin ingin menghapus ${user.fullName}?', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await _userService.deleteUser(user.id);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${user.fullName} dihapus', style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: const Color(0xFFE53935),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus: $e', style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: Text('Hapus', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature hanya bisa dilakukan melalui registrasi',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF2D5016),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _UserCard({required this.user, required this.onEdit, required this.onDelete, required this.onToggleStatus});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2D5016).withValues(alpha: 0.1)),
                child: const Icon(Icons.person, color: Color(0xFF2D5016), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(user.fullName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: user.role == 'admin' 
                                ? const Color(0xFFFF9800).withValues(alpha: 0.1) 
                                : const Color(0xFF2196F3).withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                            user.role == 'admin' ? 'Admin' : 'User', 
                            style: GoogleFonts.poppins(
                              fontSize: 10, 
                              fontWeight: FontWeight.w600, 
                              color: user.role == 'admin' ? const Color(0xFFFF9800) : const Color(0xFF2196F3)
                            )
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(user.email, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(user.phone, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(width: 14),
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('Bergabung ${_formatDate(user.createdAt)}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: user.isActive ? const Color(0xFF4CAF50) : Colors.grey)),
                    const SizedBox(width: 6),
                    Text(user.isActive ? 'Aktif' : 'Nonaktif', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: user.isActive ? const Color(0xFF4CAF50) : Colors.grey)),
                  ],
                ),
              ),
              IconButton(onPressed: onToggleStatus, icon: Icon(user.isActive ? Icons.toggle_on : Icons.toggle_off, color: user.isActive ? const Color(0xFF4CAF50) : Colors.grey, size: 32), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: Color(0xFF2196F3), size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 8),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  final UserModel? user;
  final Function(Map<String, String>) onSave;

  const _UserFormSheet({this.user, required this.onSave});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _selectedRole = widget.user?.role ?? 'user';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Edit User', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                Text('Email: ${widget.user?.email ?? ''}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 20),
                _buildTextField('Nama Lengkap', _nameController, Icons.person_outline),
                const SizedBox(height: 14),
                _buildTextField('Nomor Telepon', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                Text('Role', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF333333))),
                const SizedBox(height: 8),
                Row(
                  children: ['user', 'admin'].map((role) {
                    final isSelected = role == _selectedRole;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = role),
                        child: Container(
                          margin: EdgeInsets.only(right: role == 'user' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: isSelected ? const Color(0xFF2D5016) : const Color(0xFFF5F5F0), borderRadius: BorderRadius.circular(12)),
                          child: Text(role == 'admin' ? 'Admin' : 'User', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey[600])),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSave({
                          'name': _nameController.text,
                          'phone': _phoneController.text,
                          'role': _selectedRole,
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5016), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: Text('Simpan', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF333333))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
            filled: true,
            fillColor: const Color(0xFFF5F5F0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) => v == null || v.isEmpty ? '$label tidak boleh kosong' : null,
        ),
      ],
    );
  }
}
