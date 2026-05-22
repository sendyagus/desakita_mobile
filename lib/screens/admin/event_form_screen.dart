import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';

class EventFormScreen extends StatefulWidget {
  final Map<String, dynamic>? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _organizerController = TextEditingController();
  final _contactController = TextEditingController();
  final _imageUrlController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e != null) {
      _nameController.text = e['name'] as String? ?? '';
      _descController.text = e['description'] as String? ?? '';
      _locationController.text = e['location'] as String? ?? '';
      _categoryController.text = e['category'] as String? ?? 'Budaya';
      _priceController.text = e['price'] as String? ?? '';
      _organizerController.text = e['organizer'] as String? ?? '';
      _contactController.text = e['contact'] as String? ?? '';
      _imageUrlController.text = e['image_url'] as String? ?? '';
      _startDate = DateTime.tryParse(e['start_date'] as String? ?? '');
      _endDate = DateTime.tryParse(e['end_date'] as String? ?? '');
    } else {
      _categoryController.text = 'Budaya';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _organizerController.dispose();
    _contactController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih tanggal mulai dan selesai', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim().isEmpty
          ? 'Acara Desa'
          : _nameController.text.trim();
      final imageUrl = _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim();

      if (widget.event == null) {
        await _eventService.addEvent(
          name: name,
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          category: _categoryController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          price: _priceController.text.trim(),
          organizer: _organizerController.text.trim(),
          contact: _contactController.text.trim(),
          imageUrl: imageUrl,
        );
      } else {
        await _eventService.updateEvent(
          id: widget.event!['id'] as String,
          name: name,
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          category: _categoryController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          price: _priceController.text.trim(),
          organizer: _organizerController.text.trim(),
          contact: _contactController.text.trim(),
          imageUrl: imageUrl,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acara berhasil disimpan', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: const Color(0xFF2D5016),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Acara' : 'Tambah Acara',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field('Nama Acara (opsional)', _nameController),
            _field('Deskripsi (opsional)', _descController, maxLines: 3),
            _field('Lokasi (opsional)', _locationController),
            _field('Kategori', _categoryController, hint: 'Budaya, Festival, dll'),
            _dateTile('Tanggal Mulai *', _startDate, () => _pickDate(true)),
            _dateTile('Tanggal Selesai *', _endDate, () => _pickDate(false)),
            _field('Harga/Tiket (opsional)', _priceController),
            _field('Penyelenggara (opsional)', _organizerController),
            _field('Kontak (opsional)', _contactController),
            _field('URL Gambar (opsional)', _imageUrlController),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Simpan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: c,
            maxLines: maxLines,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2D5016)),
                  const SizedBox(width: 10),
                  Text(
                    date != null
                        ? DateFormat('dd MMMM yyyy', 'id_ID').format(date)
                        : 'Pilih tanggal',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
