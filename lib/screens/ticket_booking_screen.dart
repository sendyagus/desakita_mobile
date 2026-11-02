import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/screens/ticket_confirmation_screen.dart';
import 'package:desa_wisata/services/auth_service.dart';
import 'package:desa_wisata/services/booking_service.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';

class TicketBookingScreen extends StatefulWidget {
  final Map<String, dynamic> destination;
  const TicketBookingScreen({super.key, required this.destination});

  @override
  State<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime _visitDate = DateTime.now().add(const Duration(days: 1));
  int _guestCount = 1;
  int _step = 0;
  bool _saving = false;
  String _session = '08:00 - 12:00 WIB';
  String _paymentMethod = 'QRIS';

  static const _sessions = [
    '08:00 - 12:00 WIB',
    '12:00 - 16:00 WIB',
    '16:00 - 18:00 WIB',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      final profile = await AuthService.instance.getCurrentUserProfile();
      final authUser = FirebaseAuth.instance.currentUser;
      if (!mounted) return;
      _nameController.text = profile?.fullName ?? authUser?.displayName ?? '';
      _phoneController.text = profile?.phone ?? '';
      _emailController.text = profile?.email ?? authUser?.email ?? '';
      setState(() {});
    } catch (_) {
      // Form tetap bisa diisi manual jika profil belum tersedia.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  int get _unitPrice {
    final raw = (widget.destination['price'] ?? '').toString();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  int get _totalPrice => _unitPrice * _guestCount;

  String _rupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return '${days[value.weekday - 1]}, ${value.day} ${months[value.month - 1]} ${value.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate.isBefore(now) ? now : _visitDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: DesaKitaColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  void _continue() {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (_formKey.currentState?.validate() ?? false) setState(() => _step = 2);
      return;
    }
    _createBooking();
  }

  Future<void> _createBooking() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk sebelum memesan tiket.')),
      );
      return;
    }
    if (widget.destination['id'] == null ||
        widget.destination['id'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID destinasi tidak ditemukan.')),
      );
      return;
    }
    if (_unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harga tiket belum tersedia. Hubungi pengelola destinasi.',
          ),
        ),
      );
      return;
    }

    final startHour = int.tryParse(_session.substring(0, 2)) ?? 8;
    final endPart = _session.split(' - ').last;
    final endHour = int.tryParse(endPart.substring(0, 2)) ?? (startHour + 4);
    final checkIn = DateTime(
      _visitDate.year,
      _visitDate.month,
      _visitDate.day,
      startHour,
    );
    final checkOut = DateTime(
      _visitDate.year,
      _visitDate.month,
      _visitDate.day,
      endHour,
    );

    setState(() => _saving = true);
    try {
      final booking = await BookingService().createBooking(
        destinationId: widget.destination['id'].toString(),
        userId: uid,
        checkIn: checkIn,
        checkOut: checkOut,
        guestCount: _guestCount,
        totalPrice: _rupiah(_totalPrice),
        visitorName: _nameController.text.trim(),
        visitorPhone: _phoneController.text.trim(),
        visitorEmail: _emailController.text.trim(),
        paymentMethod: _paymentMethod,
        paymentStatus: 'awaiting_payment',
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TicketConfirmationScreen(
            booking: booking,
            destination: widget.destination,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Pesanan gagal disimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.destination['name'] ?? 'Destinasi').toString();
    final location = (widget.destination['location'] ?? '').toString();
    final steps = ['Jadwal', 'Detail', 'Pembayaran'];

    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _step == 0
              ? 'Pilih Jadwal & Sesi'
              : _step == 1
              ? 'Detail Pemesan'
              : 'Pembayaran',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: List.generate(steps.length, (index) {
                final active = index <= _step;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == steps.length - 1 ? 0 : 8,
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: active
                                ? DesaKitaColors.primary
                                : DesaKitaColors.divider,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          steps[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: active
                                ? DesaKitaColors.darkGreen
                                : DesaKitaColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(child: _buildStepContent(name, location)),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepContent(String name, String location) {
    if (_step == 0) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DestinationPhoto(
                  imageUrl: widget.destination['imageUrl']?.toString(),
                  fallbackAsset: _fallbackAsset(),
                  height: 150,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: DesaKitaColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: DesaKitaColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Pilih Tanggal Kunjungan'),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DesaKitaColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: DesaKitaColors.mutedGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: DesaKitaColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal kunjungan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: DesaKitaColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_visitDate),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: DesaKitaColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DesaKitaColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Pilih Sesi Kunjungan'),
          const SizedBox(height: 10),
          ..._sessions.map((session) {
            final selected = _session == session;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _session = session),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesaKitaColors.surfaceGreen
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? DesaKitaColors.primary
                          : DesaKitaColors.divider,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: selected
                            ? DesaKitaColors.primary
                            : DesaKitaColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          session,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DesaKitaColors.text,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? DesaKitaColors.primary
                            : DesaKitaColors.divider,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          _sectionTitle('Jumlah Pengunjung'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DesaKitaColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: DesaKitaColors.mutedGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: DesaKitaColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total pengunjung',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _unitPrice > 0
                            ? '${_rupiah(_unitPrice)} per orang'
                            : 'Harga tiket belum tersedia',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: DesaKitaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Kurangi pengunjung',
                  onPressed: _guestCount > 1
                      ? () => setState(() => _guestCount--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text(
                  '$_guestCount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.text,
                  ),
                ),
                IconButton(
                  tooltip: 'Tambah pengunjung',
                  onPressed: _guestCount < 20
                      ? () => setState(() => _guestCount++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_step == 1) {
      return Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Text(
              'Identitas Pemesan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: DesaKitaColors.text,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Pastikan informasi yang kamu masukkan benar. Informasi ini digunakan untuk detail pemesanan.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                height: 1.5,
                color: DesaKitaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            _inputLabel('Nama Lengkap'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama lengkap wajib diisi.'
                  : null,
              decoration: const InputDecoration(
                hintText: 'Masukkan nama lengkap',
              ),
            ),
            const SizedBox(height: 16),
            _inputLabel('Nomor Telepon'),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().length < 8)
                  ? 'Masukkan nomor telepon yang valid.'
                  : null,
              decoration: const InputDecoration(
                hintText: 'Contoh: 081234567890',
              ),
            ),
            const SizedBox(height: 16),
            _inputLabel('Email'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Masukkan alamat email yang valid.'
                  : null,
              decoration: const InputDecoration(hintText: 'nama@email.com'),
            ),
            const SizedBox(height: 20),
            _summaryCard(name),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        Text(
          'Metode Pembayaran',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: DesaKitaColors.text,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Pilih metode yang ingin kamu gunakan. Pembayaran elektronik belum terhubung, jadi pesanan akan disimpan dengan status menunggu pembayaran.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            height: 1.5,
            color: DesaKitaColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...[
          ('QRIS', 'Pembayaran QRIS', Icons.qr_code_2_rounded),
          ('Transfer Bank', 'Transfer bank', Icons.account_balance_outlined),
          ('E-Wallet', 'Dompet digital', Icons.account_balance_wallet_outlined),
        ].map((method) {
          final selected = _paymentMethod == method.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _paymentMethod = method.$1),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? DesaKitaColors.surfaceGreen : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? DesaKitaColors.primary
                        : DesaKitaColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(method.$3, color: DesaKitaColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        method.$2,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DesaKitaColors.text,
                        ),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected
                          ? DesaKitaColors.primary
                          : DesaKitaColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        _summaryCard(name),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF996500),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Konfirmasi ini membuat catatan pesanan di Firestore. Ini belum memproses uang atau menerbitkan QR tiket aktif.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    height: 1.45,
                    color: const Color(0xFF765200),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fallbackAsset() {
    final category = (widget.destination['category'] ?? '')
        .toString()
        .toLowerCase();
    return category.contains('kuliner') || category.contains('budaya')
        ? 'assets/img/cs2.jpg'
        : 'assets/img/cs1.jpg';
  }

  Widget _summaryCard(String name) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pesanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.text,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Destinasi', name),
          _summaryRow('Tanggal', _formatDate(_visitDate)),
          _summaryRow('Sesi', _session),
          _summaryRow('Pengunjung', '$_guestCount orang'),
          const Divider(height: 20),
          _summaryRow('Total', _rupiah(_totalPrice), emphasized: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: DesaKitaColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: emphasized ? 13 : 10,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: emphasized
                    ? DesaKitaColors.primary
                    : DesaKitaColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) => Text(
    label,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: DesaKitaColors.text,
    ),
  );
  Widget _inputLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: DesaKitaColors.text,
      ),
    ),
  );

  Widget _buildBottomBar() {
    final buttonLabel = _saving
        ? 'Menyimpan...'
        : _step == 0
        ? 'Lanjut'
        : _step == 1
        ? 'Lanjut ke Pembayaran'
        : 'Konfirmasi Pesanan';
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total estimasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: DesaKitaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _unitPrice > 0
                      ? _rupiah(_totalPrice)
                      : 'Harga belum tersedia',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.darkGreen,
                  ),
                ),
              ],
            ),
          ),
          if (_step > 0) ...[
            OutlinedButton(
              onPressed: _saving ? null : () => setState(() => _step--),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesaKitaColors.darkGreen,
                side: const BorderSide(color: DesaKitaColors.divider),
              ),
              child: const Text('Kembali'),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _saving ? null : _continue,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      buttonLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
