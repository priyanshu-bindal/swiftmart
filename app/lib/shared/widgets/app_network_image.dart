import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final Color? color;
  final BlendMode? colorBlendMode;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = Duration.zero,
    this.fadeOutDuration = Duration.zero,
    this.memCacheWidth = 400, // Clamp memory usage to sensible boundary
    this.memCacheHeight,
    this.maxWidthDiskCache = 800, // Limit disk cache file sizes
    this.maxHeightDiskCache,
    this.color,
    this.colorBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget != null
          ? errorWidget!(context, imageUrl, null)
          : const Icon(Icons.broken_image);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      color: color,
      colorBlendMode: colorBlendMode,
      fadeInDuration: fadeInDuration ?? Duration.zero,
      fadeOutDuration: fadeOutDuration ?? Duration.zero,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      placeholder:
          placeholder ??
          (context, url) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
            ),
          ),
      errorWidget:
          errorWidget ??
          (context, url, error) =>
              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }
}

