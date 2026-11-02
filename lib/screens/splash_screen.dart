import 'package:flutter/material.dart';
import 'dart:async';
import 'package:desa_wisata/widgets/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showOnboarding = false;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Selamat Datang di DesaKita",
      "subtitle": "Discover the best rural destinations in Kemiling.",
    },
    {
      "title": "Informasi lengkap dan terpercaya",
      "subtitle":
          "Jelajahi destinasi wisata dengan detail, aktivitas seru, fasilitas lengkap, hingga acara lokal untuk melengkapi perjalanan anda",
    },
    {
      "title": "Rencanakan perjalanan dengan mudah",
      "subtitle":
          "Tanya agent pintar untuk rekomendasi destinasi penginapan dan aktivitas menarik lainnya di wisata sekitar",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Delay to show the full image logo splash before showing the onboarding sheet
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showOnboarding = true;
        });
      }
    });
  }

  void _completeOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // fallback
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('assets/img/desakita.jpg', fit: BoxFit.cover),
          ),

          // Dark overlay to make text more readable
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),

          // Logo Section (Top Center)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: AnimatedOpacity(
                  opacity: _showOnboarding
                      ? 1.0
                      : 0.0, // Fade in logo or keep it visible
                  duration: const Duration(seconds: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo/LOGO NAME.png',
                        height: 40,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text(
                              "DesaKita",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/logo/LOGO OBJEK.png',
                        height: 50,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.eco,
                              color: Colors.white,
                              size: 40,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Initial Centered Logo before Onboarding appears
          AnimatedOpacity(
            opacity: _showOnboarding ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo/LOGO NAME.png',
                    height: 50,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      "DesaKita",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/logo/LOGO OBJEK.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.eco, color: Colors.white, size: 50),
                  ),
                ],
              ),
            ),
          ),

          // Onboarding Bottom Sheet (Animated Slide Up)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            bottom: _showOnboarding ? 0 : -450, // Slide up from bottom
            left: 0,
            right: 0,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: onboardingData.length,
                        itemBuilder: (context, index) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                onboardingData[index]["title"]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                onboardingData[index]["subtitle"]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Page Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        onboardingData.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _completeOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: const Text(
                            "Lewati",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPage == onboardingData.length - 1) {
                              _completeOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == onboardingData.length - 1
                                ? "Mulai Jelajahi"
                                : "Selanjutnya",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
        ],
      ),
    );
  }
}
