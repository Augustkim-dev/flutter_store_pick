import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

class CachedImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  late ImageProvider _imageProvider;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resetImage();
      _loadImage();
    }
  }

  void _resetImage() {
    _imageStream?.removeListener(_imageStreamListener!);
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
  }

  void _loadImage() {
    _imageProvider = NetworkImage(widget.imageUrl);
    final ImageStream stream = _imageProvider.resolve(ImageConfiguration.empty);
    
    _imageStreamListener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = false;
          });
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      },
    );
    
    _imageStream = stream;
    stream.addListener(_imageStreamListener!);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageStreamListener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = widget.placeholder ?? 
        SkeletonLoader(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 200,
          borderRadius: widget.borderRadius,
        );
    } else if (_hasError) {
      content = widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: widget.borderRadius,
          ),
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.grey,
            ),
          ),
        );
    } else {
      content = Image(
        image: _imageProvider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}

// 썸네일 이미지 위젯 (메모리 최적화)
class ThumbnailImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const ThumbnailImage({
    Key? key,
    required this.imageUrl,
    this.size = 60,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedImageWidget(
      imageUrl: _getThumbnailUrl(imageUrl),
      width: size,
      height: size,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      placeholder: SkeletonLoader(
        width: size,
        height: size,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  String _getThumbnailUrl(String originalUrl) {
    // Supabase Storage transform 예시
    // 실제로는 백엔드 설정에 따라 다름
    if (originalUrl.contains('supabase')) {
      return '$originalUrl?width=200&height=200';
    }
    return originalUrl;
  }
}

// 지연 로딩 이미지 리스트
class LazyImageList extends StatelessWidget {
  final List<String> imageUrls;
  final double itemHeight;
  final double itemWidth;
  final Widget Function(BuildContext, String) itemBuilder;

  const LazyImageList({
    Key? key,
    required this.imageUrls,
    required this.itemHeight,
    required this.itemWidth,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        // 화면에 보이는 것 + 앞뒤 2개씩만 로드
        final isVisible = index == 0 || 
          (index > 0 && index < imageUrls.length);
        
        if (isVisible) {
          return itemBuilder(context, imageUrls[index]);
        } else {
          // 아직 로드하지 않은 항목은 플레이스홀더
          return SizedBox(
            width: itemWidth,
            height: itemHeight,
            child: SkeletonLoader(
              width: itemWidth,
              height: itemHeight,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }
      },
    );
  }
}