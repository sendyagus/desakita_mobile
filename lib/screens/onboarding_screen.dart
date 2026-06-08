import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/widgets/auth_gate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardOpacity;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      image: 'assets/img/cs1.png',
      title: 'Selamat Datang di\nDesaKita',
      description:
          'Discover the best rural destinations in Kemiling, Bandar Lampung. Explore nature, culture, and more!',
      icon: Icons.explore_rounded,
    ),
    _OnboardingData(
      image: 'assets/img/cs2.png',
      title: 'Informasi lengkap\ndan terpercaya',
      description:
          'Akses informasi destinasi wisata, fasilitas, aktivitas, serta rekomendasi terbaik untuk perjalanan anda.',
      icon: Icons.verified_rounded,
    ),
    _OnboardingData(
      image: 'assets/img/cs3.jpg',
      title: 'Rencanakan perjalanan\ndengan mudah',
      description:
          'Tanpa agen! Cari destinasi wisata terbaik, nikmati pemandangan dan aktivitas terbaik di desa wisata Kemiling.',
      icon: Icons.map_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _cardOpacity = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeIn,
    );
    _cardController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _cardController.reset();
    _cardController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToApp();
    }
  }

  void _goToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // ── Background PageView (full screen image) ─────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 260, // tinggi card
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.asset(
                      _pages[index].image,
                      width: double.infinity,
                      fit: BoxFit.fill,

                      alignment: const Alignment(-0.2, -0.3),
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                          'Error loading image: ${_pages[index].image}',
                        );
                        return Container(
                          color: const Color(0xFF2D5016),
                          child: const Center(
                            child: Icon(
                              Icons.landscape_outlined,
                              size: 80,
                              color: Colors.white24,
                            ),
                          ),
                        );
                      },
                    ),
                    // Dark overlay for better text readability
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x22000000),
                            Color(0x00000000),
                            Color(0x00000000),
                            Color(0xDD0D1A05),
                          ],
                          stops: [0.0, 0.25, 0.45, 0.85],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Full top-to-bottom gradient overlay ─────────────────────────
          // (Sudah digabung dalam PageView.builder untuk smoother transition)

          // ── Logo top-left ────────────────────────────────────────────────
         

          // ── Bottom white card ────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardOpacity,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon badge
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0DC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _pages[_currentPage].icon,
                          color: const Color(0xFF2D5016),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      Text(
                        _pages[_currentPage].title,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        _pages[_currentPage].description,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF666666),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Dot indicators + buttons row
                      Row(
                        children: [
                          // Dot indicators
                          Row(
                            children: List.generate(_pages.length, (index) {
                              final isActive = index == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                width: isActive ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF2D5016)
                                      : const Color(0xFFCCCCCC),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),

                          const Spacer(),

                          // "Lewati" button (skip) — hidden on last page
                          if (!isLastPage)
                            TextButton(
                              onPressed: _goToApp,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF888888),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                'Lewati',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          const SizedBox(width: 8),

                          // Next / Mulai button
                          GestureDetector(
                            onTap: _nextPage,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: EdgeInsets.symmetric(
                                horizontal: isLastPage ? 28 : 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D5016),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x402D5016),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isLastPage ? 'Mulai' : 'Selanjutnya',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isLastPage
                                        ? Icons.rocket_launch_rounded
                                        : Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model for each onboarding page ──────────────────────────────────────

class _OnboardingData {
  final String image;
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingData({
    required this.image,
    required this.title,
    required this.description,
    required this.icon,
  });
}
