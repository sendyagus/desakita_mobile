import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import '../../services/booking_report_pdf_service.dart';
import '../../utils/booking_analytics_helper.dart';

class BookingAnalyticsScreen extends StatefulWidget {
  const BookingAnalyticsScreen({super.key});

  @override
  State<BookingAnalyticsScreen> createState() => _BookingAnalyticsScreenState();
}

class _BookingAnalyticsScreenState extends State<BookingAnalyticsScreen> {
  final BookingService _bookingService = BookingService();
  final BookingReportPdfService _pdfService = BookingReportPdfService();

  AnalyticsPeriod _period = AnalyticsPeriod.month;
  String _statusFilter = 'Semua';
  bool _exporting = false;

  List<Map<String, dynamic>> _applyStatusFilter(List<Map<String, dynamic>> list) {
    if (_statusFilter == 'Semua') return list;
    return list.where((b) => b['status'] == _statusFilter).toList();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportPdf(List<Map<String, dynamic>> periodBookings) async {
    setState(() => _exporting = true);
    try {
      final filtered = _applyStatusFilter(periodBookings);
      await _pdfService.printReport(
        period: _period,
        bookings: filtered,
        statusFilter: _statusFilter == 'Semua'
            ? 'Semua'
            : BookingAnalyticsHelper.statusLabel(_statusFilter),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal cetak PDF: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Laporan & Analitik',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _bookingService.watchAllBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D5016)),
            );
          }

          final all = snapshot.data ?? [];
          final periodBookings =
              BookingAnalyticsHelper.filterByPeriod(all, _period);
          final displayList = _applyStatusFilter(periodBookings);
          final counts = BookingAnalyticsHelper.countByStatus(periodBookings);
          final revenue = BookingAnalyticsHelper.parseRevenueAmount(periodBookings);
          final buckets = BookingAnalyticsHelper.barBuckets(periodBookings, _period);

          return Column(
            children: [
              _buildPeriodFilter(),
              _buildStatusFilter(),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF2D5016),
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _buildExportBar(periodBookings),
                      const SizedBox(height: 12),
                      _buildSummaryCards(counts, periodBookings.length, revenue),
                      const SizedBox(height: 16),
                      _buildPieChart(counts, periodBookings.length),
                      const SizedBox(height: 16),
                      _buildBarChart(buckets),
                      const SizedBox(height: 20),
                      Text(
                        'Detail Booking (${displayList.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (displayList.isEmpty)
                        _emptyState()
                      else
                        ...displayList.map((b) => _bookingTile(b)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExportBar(List<Map<String, dynamic>> periodBookings) {
    return Row(
      children: [
        Expanded(
          child: Text(
            BookingAnalyticsHelper.periodRangeText(_period),
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _exporting ? null : () => _exportPdf(periodBookings),
          icon: const Icon(Icons.print_outlined, size: 18),
          label: Text('Cetak PDF', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D5016),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Periode Laporan',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Row(
            children: AnalyticsPeriod.values.map((p) {
              final selected = _period == p;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      BookingAnalyticsHelper.periodLabel(p),
                      style: GoogleFonts.poppins(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _period = p),
                    selectedColor: const Color(0xFF2D5016),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.grey[800],
                    ),
                    backgroundColor: const Color(0xFFE8EDE3),
                    side: BorderSide.none,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    const filters = ['Semua', 'pending', 'confirmed', 'cancelled', 'completed'];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: filters.map((f) {
          final label = f == 'Semua' ? 'Semua' : BookingAnalyticsHelper.statusLabel(f);
          final selected = _statusFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label, style: GoogleFonts.poppins(fontSize: 11)),
              selected: selected,
              onSelected: (_) => setState(() => _statusFilter = f),
              selectedColor: const Color(0xFF2D5016),
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey[700]),
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, int> counts, int total, int revenue) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statBox('Total', '$total', const Color(0xFF2D5016))),
            const SizedBox(width: 10),
            Expanded(child: _statBox('Menunggu', '${counts['pending']}', Colors.orange)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statBox('Dikonfirmasi', '${counts['confirmed']}', const Color(0xFF2196F3))),
            const SizedBox(width: 10),
            Expanded(child: _statBox('Dibatalkan', '${counts['cancelled']}', Colors.red)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estimasi Pendapatan', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
              Text(
                BookingAnalyticsHelper.formatCurrency(revenue),
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, int> counts, int total) {
    final sections = <PieChartSectionData>[];
    final data = [
      ('pending', counts['pending'] ?? 0, Colors.orange),
      ('confirmed', counts['confirmed'] ?? 0, const Color(0xFF2196F3)),
      ('cancelled', counts['cancelled'] ?? 0, Colors.red),
      ('completed', counts['completed'] ?? 0, const Color(0xFF4CAF50)),
    ];

    for (final (_, value, color) in data) {
      if (value == 0) continue;
      final pct = total > 0 ? (value / total * 100) : 0.0;
      sections.add(
        PieChartSectionData(
          value: value.toDouble(),
          color: color,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 52,
          titleStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      );
    }

    return _chartCard(
      title: 'Diagram Status Booking',
      child: total == 0
          ? _chartEmpty()
          : SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: sections.isEmpty
                            ? [PieChartSectionData(value: 1, color: Colors.grey[300]!, title: '')]
                            : sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: d.$3, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(
                                '${BookingAnalyticsHelper.statusLabel(d.$1)} (${d.$2})',
                                style: GoogleFonts.poppins(fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBarChart(List<BarBucket> buckets) {
    final maxY = buckets.isEmpty
        ? 4.0
        : (buckets.map((b) => b.count).reduce((a, b) => a > b ? a : b) + 1)
            .clamp(4, 999)
            .toDouble();

    return _chartCard(
      title: 'Diagram Booking per Waktu',
      child: buckets.every((b) => b.count == 0)
          ? _chartEmpty()
          : SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: GoogleFonts.poppins(fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (i, _) {
                          if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              buckets[i.toInt()].label,
                              style: GoogleFonts.poppins(fontSize: 8),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1.0,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(buckets.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: buckets[i].count.toDouble(),
                          color: const Color(0xFF2D5016),
                          width: 14,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
    );
  }

  Widget _chartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _chartEmpty() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Belum ada data pada periode ini',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Tidak ada booking pada filter ini',
          style: GoogleFonts.poppins(color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _bookingTile(Map<String, dynamic> b) {
    final dest = b['destinations'] as Map<String, dynamic>? ?? {};
    final user = b['users'] as Map<String, dynamic>? ?? {};
    final status = b['status'] as String? ?? 'pending';
    final created = BookingAnalyticsHelper.parseCreatedAt(b);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dest['name'] as String? ?? '-',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  BookingAnalyticsHelper.statusLabel(status),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user['full_name'] as String? ?? user['email'] as String? ?? '-',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            '${b['total_price']} • ${created != null ? DateFormat('dd MMM yyyy', 'id_ID').format(created) : '-'}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
