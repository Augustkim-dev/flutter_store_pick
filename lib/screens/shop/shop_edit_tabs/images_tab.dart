import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/shop.dart';
import '../../../theme/app_colors.dart';

class ImagesTab extends StatefulWidget {
  final Shop shop;
  final String? mainImageUrl;
  final List<String> galleryImageUrls;
  final ValueChanged<String?> onMainImageChanged;
  final ValueChanged<List<String>> onGalleryImagesChanged;

  const ImagesTab({
    Key? key,
    required this.shop,
    required this.mainImageUrl,
    required this.galleryImageUrls,
    required this.onMainImageChanged,
    required this.onGalleryImagesChanged,
  }) : super(key: key);

  @override
  State<ImagesTab> createState() => _ImagesTabState();
}

class _ImagesTabState extends State<ImagesTab> {
  final ImagePicker _picker = ImagePicker();
  File? _mainImageFile;
  List<File> _galleryImageFiles = [];

  Future<void> _pickMainImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _mainImageFile = File(image.path);
        });
        // TODO: Supabase Storage 업로드 구현
        widget.onMainImageChanged(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _galleryImageFiles.addAll(images.map((img) => File(img.path)));
        });
        
        // TODO: Supabase Storage 업로드 구현
        final updatedUrls = List<String>.from(widget.galleryImageUrls);
        updatedUrls.addAll(images.map((img) => img.path));
        widget.onGalleryImagesChanged(updatedUrls);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  void _removeGalleryImage(int index) {
    final updatedUrls = List<String>.from(widget.galleryImageUrls);
    updatedUrls.removeAt(index);
    widget.onGalleryImagesChanged(updatedUrls);
    
    if (index < _galleryImageFiles.length) {
      setState(() {
        _galleryImageFiles.removeAt(index);
      });
    }
  }

  Widget _buildImageWidget(String? url, File? file) {
    if (file != null) {
      return Image.file(
        file,
        fit: BoxFit.cover,
      );
    } else if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      } else {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      }
    }
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 이미지
          _buildSectionTitle('메인 이미지'),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickMainImage,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageWidget(widget.mainImageUrl, _mainImageFile),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '클릭하여 메인 이미지 변경',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '권장 크기: 1200x1200px, 최대 5MB',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // 갤러리 이미지
          _buildSectionTitle('갤러리 이미지'),
          const SizedBox(height: 12),
          
          // 이미지 추가 버튼
          OutlinedButton.icon(
            onPressed: _pickGalleryImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('이미지 추가'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryPink,
              side: const BorderSide(color: AppColors.primaryPink),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // 갤러리 이미지 그리드
          if (widget.galleryImageUrls.isNotEmpty || _galleryImageFiles.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: widget.galleryImageUrls.length,
              itemBuilder: (context, index) {
                final url = widget.galleryImageUrls[index];
                File? file;
                if (index < _galleryImageFiles.length) {
                  file = _galleryImageFiles[index];
                }
                
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: _buildImageWidget(url, file),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeGalleryImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    // 순서 표시
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '드래그하여 순서를 변경할 수 있습니다 (준비 중)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.collections_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '갤러리 이미지가 없습니다',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '매장 내부, 상품 등의 이미지를 추가하세요',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // 도움말
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 20,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이미지 가이드',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• 밝고 선명한 이미지를 사용하세요\n'
                        '• 메인 이미지는 상점을 대표하는 이미지로\n'
                        '• 갤러리는 최대 10장까지 등록 가능\n'
                        '• 저작권이 있는 이미지는 사용 불가',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}