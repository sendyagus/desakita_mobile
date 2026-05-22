import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/booking_analytics_helper.dart';

class BookingReportPdfService {
  Future<void> printReport({
    required AnalyticsPeriod period,
    required List<Map<String, dynamic>> bookings,
    String statusFilter = 'Semua',
  }) async {
    final doc = await _buildDocument(
      period: period,
      bookings: bookings,
      statusFilter: statusFilter,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'laporan-booking-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  Future<void> sharePdf({
    required AnalyticsPeriod period,
    required List<Map<String, dynamic>> bookings,
    String statusFilter = 'Semua',
  }) async {
    final doc = await _buildDocument(
      period: period,
      bookings: bookings,
      statusFilter: statusFilter,
    );
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'laporan-booking-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  Future<pw.Document> _buildDocument({
    required AnalyticsPeriod period,
    required List<Map<String, dynamic>> bookings,
    required String statusFilter,
  }) async {
    final counts = BookingAnalyticsHelper.countByStatus(bookings);
    final revenue = BookingAnalyticsHelper.parseRevenueAmount(bookings);
    final buckets = BookingAnalyticsHelper.barBuckets(bookings, period);
    final generated = DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now());
    final dateFmt = DateFormat('dd/MM/yyyy', 'id_ID');

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Laporan Booking — DesaKita',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Periode: ${BookingAnalyticsHelper.periodLabel(period)}'),
                pw.Text(BookingAnalyticsHelper.periodRangeText(period)),
                pw.Text('Filter status: $statusFilter'),
                pw.Text('Dicetak: $generated'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Ringkasan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Indikator', 'Nilai'],
            data: [
              ['Total Booking', '${bookings.length}'],
              ['Menunggu', '${counts['pending']}'],
              ['Dikonfirmasi', '${counts['confirmed']}'],
              ['Dibatalkan', '${counts['cancelled']}'],
              ['Selesai', '${counts['completed']}'],
              ['Estimasi Pendapatan', BookingAnalyticsHelper.formatCurrency(revenue)],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Grafik — Booking per Periode', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Periode', 'Jumlah Booking'],
            data: buckets.map((b) => [b.label, '${b.count}']).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: pw.TableBorder.all(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Detail Booking', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (bookings.isEmpty)
            pw.Text('Tidak ada data pada periode ini.')
          else
            pw.Table.fromTextArray(
              headers: ['No', 'Destinasi', 'Pelanggan', 'Status', 'Total', 'Tanggal'],
              data: List.generate(bookings.length, (i) {
                final b = bookings[i];
                final dest = b['destinations'] as Map<String, dynamic>? ?? {};
                final user = b['users'] as Map<String, dynamic>? ?? {};
                final created = BookingAnalyticsHelper.parseCreatedAt(b);
                return [
                  '${i + 1}',
                  dest['name'] as String? ?? '-',
                  user['full_name'] as String? ?? user['email'] as String? ?? '-',
                  BookingAnalyticsHelper.statusLabel(b['status'] as String? ?? ''),
                  b['total_price'] as String? ?? '-',
                  created != null ? dateFmt.format(created) : '-',
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              border: pw.TableBorder.all(color: PdfColors.grey300),
            ),
        ],
      ),
    );

    return doc;
  }
}
