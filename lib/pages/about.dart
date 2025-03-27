import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width <= 640;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.1638, 0.5879, 0.7654, 0.9084],
            colors: [
              Color(0xFFF8FECD),
              Color(0xFFFCD6C6),
              Color(0x7AC4A5CC),
              Color(0x96967DD0),
            ],
          ),
          borderRadius: BorderRadius.circular(44),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  17,
                  isSmallScreen ? 60 : 72,
                  17,
                  50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(
                          top: isSmallScreen ? 0 : 20,
                          left: 0,
                          right: 0,
                        ),
                        child: Image.asset(
                          'assets/icons/adaptive_icon_foreground.png',
                          width: isSmallScreen ? screenSize.width * 0.8 : 386,
                          height: isSmallScreen ? null : 386,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Heading
                    Text(
                      'Hear Our Motives',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // First paragraph
                    Text(
                      'At WellBites, we believe that good health starts with good nutrition. '
                      'Our mission is to empower you to take control of your diet, make informed choices, '
                      'and achieve your health goals—whether it\'s losing weight, building muscle, '
                      'or simply feeling your best every day.',
                      style: TextStyle(
                        color: Color(0xFF534C90),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 25 / 12, // line-height / font-size
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Second paragraph
                    Text(
                      'We understand that navigating the world of nutrition can be overwhelming. '
                      'That\'s why we\'ve created a simple, intuitive, and science-backed app that '
                      'helps you track your meals, monitor your nutrient intake, and stay on top of your health journey.',
                      style: TextStyle(
                        color: Color(0xFF534C90),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 25 / 12,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(height: 17),
                    Text(
                      'Hear Our Motives',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Third paragraph
                    Text(
                      'Whether you\'re just starting your health journey or looking to take it to the next level, '
                      'WellBites is here to support you every step of the way. Let\'s build a healthier future—together!',
                      style: TextStyle(
                        color: Color(0xFF534C90),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 25 / 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom indicator
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 34,
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 144,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
