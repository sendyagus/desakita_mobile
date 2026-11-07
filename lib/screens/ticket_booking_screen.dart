import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/models/ai_chat_models.dart';
import 'package:desa_wisata/screens/ticket_confirmation_screen.dart';
import 'package:desa_wisata/services/auth_service.dart';
import 'package:desa_wisata/services/booking_service.dart';
import 'package:desa_wisata/services/trip_plan_service.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';

class TicketBookingScreen extends StatefulWidget {
  final Map<String, dynamic> destination;

  /// Jadwal hasil KITA AI. Bila diisi, itinerary ikut tersimpan sebagai
  /// "Susunan Perjalanan" begitu pemesanan berhasil dan muncul di Trip.
  final AiItinerary? itinerary;

  const TicketBookingScreen({
    super.key,
    required this.destination,
    this.itinerary,
  });

  @override
  State<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime _visitDate = DateTime.now().add(const Duration(days: 1));
  int _adultCount = 1;
  int _childCount = 0;
  int _step = 0;
  bool _saving = false;
  String _paymentMethod = 'QRIS';

  /// Kode negara tetap pada field telepon, jadi pengguna cukup mengetik
  /// nomor lokal (mis. 81234567890).
  static const _countryCode = '+62';

  /// Bulan yang sedang tampil pada kalender.
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  /// Indeks sesi terpilih pada [_sessions].
  int _sessionIndex = 0;

  static const _sessions = <_VisitSession>[
    _VisitSession(
      name: 'Sesi Pagi',
      startHour: 8,
      endHour: 12,
      icon: Icons.wb_sunny_rounded,
      iconBg: Color(0xFFFDF1DC),
      iconColor: Color(0xFFE29112),
    ),
    _VisitSession(
      name: 'Sesi Siang',
      startHour: 12,
      endHour: 16,
      icon: Icons.wb_twilight_rounded,
      iconBg: Color(0xFFE8F1FF),
      iconColor: Color(0xFF3B82F6),
    ),
    _VisitSession(
      name: 'Sesi Sore',
      startHour: 16,
      endHour: 18,
      icon: Icons.nights_stay_rounded,
      iconBg: Color(0xFFEDE9FE),
      iconColor: Color(0xFF6D5BD0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Kalender dibuka pada bulan tanggal bawaan.
    _visibleMonth = DateTime(_visitDate.year, _visitDate.month);
    _ensureSessionAvailable();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      final profile = await AuthService.instance.getCurrentUserProfile();
      final authUser = FirebaseAuth.instance.currentUser;
      if (!mounted) return;
      _nameController.text = profile?.fullName ?? authUser?.displayName ?? '';
      _phoneController.text = _localPhone(profile?.phone ?? '');
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

  /// Harga tiket dewasa mengikuti field `price` destinasi.
  int get _adultPrice {
    final raw = (widget.destination['price'] ?? '').toString();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// Harga tiket anak memakai field `childPrice` bila tersedia; kalau tidak,
  /// 75% harga dewasa yang dibulatkan ke Rp 500 terdekat.
  int get _childPrice {
    final raw =
        (widget.destination['childPrice'] ??
                widget.destination['price_child'] ??
                '')
            .toString();
    final parsed = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (parsed > 0) return parsed;
    if (_adultPrice <= 0) return 0;
    return (_adultPrice * 0.75 / 500).round() * 500;
  }

  int get _guestCount => _adultCount + _childCount;

  int get _totalPrice => _adultPrice * _adultCount + _childPrice * _childCount;

  /// Nomor lokal saja (tanpa +62/0) untuk kolom bertuliskan +62.
  static String _localPhone(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('62')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  String get _fullPhone => '$_countryCode${_localPhone(_phoneController.text)}';

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

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const _weekdayHeaders = [
    'MIN',
    'SEN',
    'SEL',
    'RAB',
    'KAM',
    'JUM',
    'SAB',
  ];

  static const _dayNames = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  String _formatDate(DateTime value) =>
      '${_dayNames[value.weekday % 7]}, ${value.day} '
      '${_monthNames[value.month - 1]} ${value.year}';

  /// Ringkasan pendek pada bilah bawah, mis. "Jumat 18 Agustus, Pagi".
  String get _scheduleLabel =>
      '${_dayNames[_visitDate.weekday % 7]} ${_visitDate.day} '
      '${_monthNames[_visitDate.month - 1]}, ${_sessions[_sessionIndex].shortName}';

  String _monthLabel(DateTime month) =>
      '${_monthNames[month.month - 1]} ${month.year}';

  /// Kalender tidak bisa mundur sebelum bulan berjalan.
  bool get _canGoPrevMonth {
    final now = DateTime.now();
    return _visibleMonth.year * 12 + _visibleMonth.month >
        now.year * 12 + now.month;
  }

  void _shiftMonth(int delta) {
    setState(
      () => _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      ),
    );
  }

  void _selectDate(DateTime date) {
    setState(() {
      _visitDate = date;
      _ensureSessionAvailable();
    });
  }

  /// Sesi pada hari-H tidak bisa dipilih bila jam mulainya sudah lewat.
  bool _isSessionAvailable(_VisitSession session) {
    final now = DateTime.now();
    final sameDay =
        _visitDate.year == now.year &&
        _visitDate.month == now.month &&
        _visitDate.day == now.day;
    if (!sameDay) return true;
    return session.startHour > now.hour;
  }

  /// Pindah ke sesi pertama yang masih tersedia.
  void _ensureSessionAvailable() {
    if (_isSessionAvailable(_sessions[_sessionIndex])) return;
    for (var i = 0; i < _sessions.length; i++) {
      if (_isSessionAvailable(_sessions[i])) {
        _sessionIndex = i;
        return;
      }
    }
  }

  _VisitSession get _selectedSession => _sessions[_sessionIndex];

  void _continue() {
    if (_step == 0) {
      if (!_isSessionAvailable(_selectedSession)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Semua sesi pada tanggal ini sudah lewat. Pilih tanggal lain.',
            ),
          ),
        );
        return;
      }
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
    if (_adultPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harga tiket belum tersedia. Hubungi pengelola destinasi.',
          ),
        ),
      );
      return;
    }

    final session = _selectedSession;
    final checkIn = DateTime(
      _visitDate.year,
      _visitDate.month,
      _visitDate.day,
      session.startHour,
    );
    final checkOut = DateTime(
      _visitDate.year,
      _visitDate.month,
      _visitDate.day,
      session.endHour,
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
        visitorPhone: _fullPhone,
        visitorEmail: _emailController.text.trim(),
        paymentMethod: _paymentMethod,
        paymentStatus: 'awaiting_payment',
      );
      if (!mounted) return;
      await _storeTripPlan(booking, checkIn: checkIn, session: session);
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

  /// Simpan jadwal perjalanan supaya muncul di halaman Trip. Urutan prioritas:
  /// itinerary yang dikirim KITA AI, lalu jadwal yang pernah disimpan untuk
  /// destinasi & tanggal sama, terakhir jadwal standar dari sesi tiket.
  Future<void> _storeTripPlan(
    Map<String, dynamic> booking, {
    required DateTime checkIn,
    required _VisitSession session,
  }) async {
    final service = TripPlanService.instance;
    final bookingId = booking['id']?.toString();
    final saved = await service.load();
    final plan = widget.itinerary == null
        ? service.planForBooking(booking, saved)
        : service.planFromItinerary(
            widget.itinerary!,
            visitDate: checkIn,
            startHour: session.startHour,
            bookingId: bookingId,
          );
    await service.saveForBooking(plan.copyWith(bookingId: bookingId));
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
          onPressed: () {
            // Tombol kembali memundurkan satu langkah, bukan keluar layar.
            if (_step > 0) {
              setState(() => _step--);
              return;
            }
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _step == 0
              ? 'Pilih Jadwal & Sesi'
              : _step == 1
              ? 'Detail Booking'
              : 'Pembayaran',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: List.generate(steps.length, (index) {
                final active = index == _step;
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
          _destinationHeader(name, location),
          const SizedBox(height: 18),
          _calendarCard(),
          const SizedBox(height: 18),
          _sectionTitle('Pilih Sesi Kunjungan'),
          const SizedBox(height: 10),
          ...List.generate(_sessions.length, _sessionCard),
        ],
      );
    }

    if (_step == 1) {
      return Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            _bookingSummaryCard(name),
            const SizedBox(height: 16),
            _priceCard(),
            const SizedBox(height: 16),
            _identityCard(),
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

  /// Kartu foto destinasi: nama dan alamat ditumpuk di atas gambar.
  Widget _destinationHeader(String name, String location) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          DestinationPhoto(
            imageUrl: widget.destination['imageUrl']?.toString(),
            fallbackAsset: _fallbackAsset(),
            height: 150,
            width: double.infinity,
            borderRadius: BorderRadius.zero,
          ),
          // Gelap di bagian bawah agar teks tetap terbaca.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xB3000000)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white,
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
    );
  }

  /// Kartu kalender: judul + navigasi bulan, lalu grid tanggal.
  Widget _calendarCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('Pilih Tanggal')),
              _monthArrow(
                Icons.chevron_left_rounded,
                enabled: _canGoPrevMonth,
                onTap: () => _shiftMonth(-1),
              ),
              const SizedBox(width: 6),
              _monthArrow(
                Icons.chevron_right_rounded,
                enabled: true,
                onTap: () => _shiftMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _monthLabel(_visibleMonth),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final label in _weekdayHeaders)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: DesaKitaColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ..._weekRows(),
        ],
      ),
    );
  }

  Widget _monthArrow(
    IconData icon, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: DesaKitaColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? DesaKitaColors.text
              : const Color(0xFFC7CBC0), // tanggal/bulan tidak aktif
        ),
      ),
    );
  }

  /// Baris per minggu. Hari di luar bulan tampil abu-abu dan tidak terpilih.
  List<Widget> _weekRows() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(firstDay.year, firstDay.month + 1, 0).day;
    final daysInPrevMonth = DateTime(firstDay.year, firstDay.month, 0).day;
    final leading = firstDay.weekday % 7; // kalender dimulai hari Minggu
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final cells = <Widget>[];
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;
    for (var i = 0; i < totalCells; i++) {
      final number = i - leading + 1;
      final inMonth = number >= 1 && number <= daysInMonth;
      final label = inMonth
          ? '$number'
          : number < 1
          ? '${daysInPrevMonth + number}'
          : '${number - daysInMonth}';
      final date = inMonth
          ? DateTime(firstDay.year, firstDay.month, number)
          : null;
      final selectable = date != null && !date.isBefore(startOfToday);
      cells.add(
        Expanded(
          child: _dayCell(
            label: label,
            date: selectable ? date : null,
            isToday: date != null && _sameDay(date, now),
            isSelected: date != null && _sameDay(date, _visitDate),
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: cells.sublist(i, i + 7)),
        ),
      );
    }
    return rows;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dayCell({
    required String label,
    DateTime? date,
    required bool isToday,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: date == null ? null : () => _selectDate(date),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? DesaKitaColors.darkGreen
                : isToday
                ? DesaKitaColors.mutedGreen
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : date == null
                      ? const Color(0xFFC7CBC0)
                      : DesaKitaColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionCard(int index) {
    final session = _sessions[index];
    final selected = _sessionIndex == index;
    final available = _isSessionAvailable(session);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: available ? () => setState(() => _sessionIndex = index) : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? DesaKitaColors.surfaceGreen : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? DesaKitaColors.primary : DesaKitaColors.divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Opacity(
            opacity: available ? 1 : 0.55,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: session.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(session.icon, color: session.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        session.timeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: DesaKitaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _availabilityBadge(available),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _availabilityBadge(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: available ? DesaKitaColors.warmSurface : DesaKitaColors.divider,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'TERSEDIA' : 'LEWAT',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: available
              ? DesaKitaColors.darkGreen
              : DesaKitaColors.textSecondary,
        ),
      ),
    );
  }

  /// Kartu putih umum pada langkah detail.
  Widget _card({
    required List<Widget> children,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Foto, nama, tanggal, dan sesi yang sudah dipilih.
  Widget _bookingSummaryCard(String name) {
    return _card(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            DestinationPhoto(
              imageUrl: widget.destination['imageUrl']?.toString(),
              fallbackAsset: _fallbackAsset(),
              width: 72,
              height: 72,
              borderRadius: BorderRadius.circular(14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: DesaKitaColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _metaRow(
                    Icons.calendar_month_outlined,
                    _formatDate(_visitDate),
                  ),
                  const SizedBox(height: 6),
                  _metaRow(
                    Icons.access_time_rounded,
                    _selectedSession.timeLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metaRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: DesaKitaColors.textSecondary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DesaKitaColors.text,
            ),
          ),
        ),
      ],
    );
  }

  /// Rincian harga dewasa/anak beserta pengatur jumlahnya.
  Widget _priceCard() {
    return _card(
      children: [
        _sectionTitle('Harga Masuk'),
        const SizedBox(height: 14),
        _priceRow(
          label: 'Dewasa',
          price: _adultPrice,
          count: _adultCount,
          minCount: 1,
          onChange: (value) => setState(() => _adultCount = value),
        ),
        const SizedBox(height: 14),
        _priceRow(
          label: 'Anak-anak',
          price: _childPrice,
          count: _childCount,
          minCount: 0,
          onChange: (value) => setState(() => _childCount = value),
        ),
      ],
    );
  }

  Widget _priceRow({
    required String label,
    required int price,
    required int count,
    required int minCount,
    required ValueChanged<int> onChange,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: DesaKitaColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                price > 0
                    ? '${_rupiah(price)} / orang'
                    : 'Harga belum tersedia',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: DesaKitaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _stepButton(
          icon: Icons.remove_rounded,
          filled: false,
          onTap: count > minCount && count > 1
              ? () => onChange(count - 1)
              : null,
        ),
        SizedBox(
          width: 26,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.text,
            ),
          ),
        ),
        _stepButton(
          icon: Icons.add_rounded,
          filled: true,
          onTap: count < 20 ? () => onChange(count + 1) : null,
        ),
      ],
    );
  }

  /// Tombol lingkaran kecil: minus bergaris, plus hijau terisi.
  Widget _stepButton({
    required IconData icon,
    required bool filled,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: filled ? DesaKitaColors.darkGreen : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled
                  ? DesaKitaColors.darkGreen
                  : DesaKitaColors.borderMuted,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: filled ? Colors.white : DesaKitaColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Data pemesan: nama, telepon (+62 tetap), dan email.
  Widget _identityCard() {
    return _card(
      children: [
        _sectionTitle('Identitas Pemesan'),
        const SizedBox(height: 14),
        _inputLabel('Nama Lengkap'),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
          decoration: _fieldDecoration('Masukkan nama sesuai KTP'),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Nama lengkap belum diisi' : null,
        ),
        const SizedBox(height: 14),
        _inputLabel('Nomor Telepon'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _phonePrefix(),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.plusJakartaSans(fontSize: 12),
                decoration: _fieldDecoration('812 3456 7890'),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(' ', '').trim();
                  if (digits.isEmpty) return 'Nomor telepon belum diisi';
                  if (digits.length < 9 || digits.length > 13) {
                    return 'Nomor telepon tidak valid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _inputLabel('Email'),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
          decoration: _fieldDecoration('contoh@email.com'),
          validator: (value) {
            final email = (value ?? '').trim();
            if (email.isEmpty) return 'Email belum diisi';
            if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
              return 'Format email belum benar';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        _noteBox(
          'E-tiket akan dikirimkan ke email dan nomor telepon yang Anda daftarkan.',
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(
      fontSize: 11,
      color: DesaKitaColors.textSecondary.withValues(alpha: 0.6),
    ),
    filled: true,
    fillColor: const Color(0xFFF2F3EE),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: DesaKitaColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: DesaKitaColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: DesaKitaColors.primary),
    ),
    errorStyle: GoogleFonts.plusJakartaSans(fontSize: 10),
  );

  /// Kotak kode negara di samping kolom nomor telepon.
  Widget _phonePrefix() {
    return Container(
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Text(
        _countryCode,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: DesaKitaColors.text,
        ),
      ),
    );
  }

  Widget _noteBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesaKitaColors.warmSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mail_outline_rounded,
            size: 16,
            color: DesaKitaColors.darkGreen,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                height: 1.5,
                color: DesaKitaColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
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
          _summaryRow(
            'Sesi',
            '${_selectedSession.name} (${_selectedSession.timeLabel})',
          ),
          _summaryRow(
            'Dewasa ($_adultCount)',
            _rupiah(_adultPrice * _adultCount),
          ),
          if (_childCount > 0)
            _summaryRow(
              'Anak-anak ($_childCount)',
              _rupiah(_childPrice * _childCount),
            ),
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
        ? 'Lanjut Pembayaran'
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
                  _step == 0
                      ? 'Jadwal Terpilih'
                      : _step == 1
                      ? 'Total'
                      : 'Total pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: DesaKitaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _step == 0
                      ? _scheduleLabel
                      : _adultPrice > 0
                      ? _rupiah(_totalPrice)
                      : 'Harga belum tersedia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _step == 0
                        ? DesaKitaColors.text
                        : DesaKitaColors.darkGreen,
                  ),
                ),
              ],
            ),
          ),
          if (_step == 2) ...[
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

/// Sesi kunjungan pada langkah jadwal: nama, rentang jam, dan ikonnya.
class _VisitSession {
  final String name;
  final int startHour;
  final int endHour;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _VisitSession({
    required this.name,
    required this.startHour,
    required this.endHour,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  /// Mis. "08:00 – 12:00 WIB".
  String get timeLabel => '${_clock(startHour)} – ${_clock(endHour)} WIB';

  /// Mis. "Pagi", dipakai pada ringkasan di bilah bawah.
  String get shortName => name.split(' ').last;

  static String _clock(int hour) => '${hour.toString().padLeft(2, '0')}:00';
}
