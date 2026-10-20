import 'package:flutter/material.dart';
import '../models/bus.dart';

Widget buildSmartBusImage(
  String url, {
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  if (url.startsWith('assets/')) {
    return Image.asset(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          errorWidget ??
          Container(
            color: Colors.grey.shade300,
            child: Center(
              child: Icon(Icons.directions_bus_filled_outlined,
                  size: 48, color: Colors.grey.shade500),
            ),
          ),
    );
  }
  return Image.network(
    url,
    fit: fit,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return placeholder ??
          Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF9E1A1A),
            ),
          );
    },
    errorBuilder: (context, error, stackTrace) {
      return errorWidget ??
          Container(
            color: Colors.grey.shade300,
            child: Center(
              child: Icon(Icons.directions_bus_filled_outlined,
                  size: 48, color: Colors.grey.shade500),
            ),
          );
    },
  );
}

class BusImageBanner extends StatelessWidget {
  final Bus bus;
  final double height;
  final BorderRadius? borderRadius;
  final bool showBadge;

  const BusImageBanner({
    super.key,
    required this.bus,
    this.height = 130,
    this.borderRadius,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final images = bus.images.isNotEmpty ? bus.images : [bus.imageUrl];
    final displayUrl = images.firstWhere((img) => img.isNotEmpty, orElse: () => '');

    return GestureDetector(
      onTap: () => showBusPhotoGallery(context, bus),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: Container(
          height: height,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (displayUrl.isNotEmpty)
                buildSmartBusImage(displayUrl, fit: BoxFit.cover)
              else
                Container(
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Icon(Icons.directions_bus_filled_outlined,
                        size: 48, color: Colors.grey.shade500),
                  ),
                ),

              // Gradient Overlay at the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              // Bus Type badge on bottom-left
              Positioned(
                bottom: 8,
                left: 10,
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      bus.busType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                      ),
                    ),
                  ],
                ),
              ),

              // Photos count badge on top-right (RedBus style)
              if (showBadge && images.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${images.length} Photos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showBusPhotoGallery(BuildContext context, Bus bus, {int initialIndex = 0}) {
  final images = bus.images.isNotEmpty ? bus.images : [bus.imageUrl];
  if (images.isEmpty) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BusPhotoGalleryModal(bus: bus, images: images, initialIndex: initialIndex),
  );
}

class _BusPhotoGalleryModal extends StatefulWidget {
  final Bus bus;
  final List<String> images;
  final int initialIndex;

  const _BusPhotoGalleryModal({
    required this.bus,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_BusPhotoGalleryModal> createState() => _BusPhotoGalleryModalState();
}

class _BusPhotoGalleryModalState extends State<_BusPhotoGalleryModal> {
  late PageController _pageController;
  late int _currentIndex;

  static const List<String> _captions = [
    'Exterior Coach & Front View',
    'Passenger Cabin & Interior Seats',
    'Berth & Highway Transit View',
    'Comfort Seating & Clean Environment',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bus.busName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.bus.busType} • ${widget.bus.busNumber}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Main Image View with Pinch to Zoom
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
              },
              itemBuilder: (context, index) {
                final url = widget.images[index];
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.5,
                  child: Center(
                    child: buildSmartBusImage(
                      url,
                      fit: BoxFit.contain,
                      placeholder: const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      ),
                      errorWidget: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.grey.shade600),
                          const SizedBox(height: 12),
                          const Text('Image not available',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              _captions[_currentIndex % _captions.length],
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),

          // Thumbnail Row
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: buildSmartBusImage(
                        widget.images[index],
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.directions_bus, color: Colors.white38, size: 18),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
