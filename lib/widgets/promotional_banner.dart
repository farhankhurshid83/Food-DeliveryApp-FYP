import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CustomCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final double height;
  final Duration autoPlayInterval;
  final bool showEnlarge;
  final BorderRadius borderRadius;
  final bool showIndicators;
  final double overlayOpacity;
  final Color indicatorColor;
  final Color activeIndicatorColor;

  const CustomCarousel({
    super.key,
    required this.imagePaths,
    this.height = 170,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.showEnlarge = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.showIndicators = true,
    this.overlayOpacity = 0.3,
    this.indicatorColor = Colors.white54,
    this.activeIndicatorColor = Colors.white,
  });

  @override
  _CustomCarouselState createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: widget.height,
            autoPlay: true,
            autoPlayInterval: widget.autoPlayInterval,
            enlargeCenterPage: widget.showEnlarge,
            viewportFraction: 0.85,
            aspectRatio: 16 / 9,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: widget.imagePaths.asMap().entries.map((entry) {
            final index = entry.key;
            final path = entry.value;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImage(
                      imagePath: path,
                      tag: 'image-$index',
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'image-$index',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: widget.borderRadius,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          path,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha:widget.overlayOpacity),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: AnimatedOpacity(
                            opacity: _currentIndex == index ? 1.0 : 0.5,
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              'Promotion ${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.showIndicators)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AnimatedSmoothIndicator(
              activeIndex: _currentIndex,
              count: widget.imagePaths.length,
              effect: WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                spacing: 12,
                dotColor: widget.indicatorColor,
                activeDotColor: widget.activeIndicatorColor,
                paintStyle: PaintingStyle.fill,
              ),
            ),
          ),
      ],
    );
  }
}

// Full-screen image view
class FullScreenImage extends StatelessWidget {
  final String imagePath;
  final String tag;

  const FullScreenImage({super.key, required this.imagePath, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: tag,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
