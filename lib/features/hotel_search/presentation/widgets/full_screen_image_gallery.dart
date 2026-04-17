import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full-screen swipeable gallery with pinch-zoom (used for hotel + room photos).
class FullScreenImageGallery extends StatefulWidget {
  final List<String> urls;
  final String title;

  const FullScreenImageGallery({
    super.key,
    required this.urls,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> urls,
    required String title,
  }) {
    if (urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No photos available.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return Future.value();
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (ctx) => FullScreenImageGallery(urls: urls, title: title),
    );
  }

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _galleryPage(String url) {
    final t = url.trim();
    if (t.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 56),
      );
    }
    final net =
        t.startsWith('http://') || t.startsWith('https://');
    final Widget image = net
        ? Image.network(
            t,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white38,
              size: 56,
            ),
            loadingBuilder: (_, child, prog) => prog == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
          )
        : Image.asset(
            t,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white38,
              size: 56,
            ),
          );
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(child: image),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _galleryPage(widget.urls[i]),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24.h,
                child: Text(
                  '${_index + 1} / ${widget.urls.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
