import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'supabase_service.dart';

class ImageUploadService {
  final SupabaseService _supabaseService = SupabaseService();
  static const String _bucketName = 'shop-images';
  
  // 업로드 진행률 콜백
  Function(double)? onProgress;

  ImageUploadService({this.onProgress});

  // 메인 이미지 업로드
  Future<String?> uploadMainImage({
    required String shopId,
    required XFile imageFile,
  }) async {
    try {
      final fileName = _generateFileName(shopId, 'main', imageFile.path);
      final filePath = 'shops/$shopId/main/$fileName';
      
      // 기존 메인 이미지 삭제
      await _deleteExistingMainImage(shopId);
      
      // 새 이미지 업로드
      final imageBytes = await imageFile.readAsBytes();
      final response = await _supabaseService.client.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      if (response.isNotEmpty) {
        // Public URL 가져오기
        final publicUrl = _supabaseService.client.storage
            .from(_bucketName)
            .getPublicUrl(filePath);
        
        return publicUrl;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading main image: $e');
      }
      return null;
    }
  }

  // 갤러리 이미지 업로드
  Future<List<String>> uploadGalleryImages({
    required String shopId,
    required List<XFile> imageFiles,
  }) async {
    final uploadedUrls = <String>[];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final imageFile = imageFiles[i];
        final fileName = _generateFileName(shopId, 'gallery_${i + 1}', imageFile.path);
        final filePath = 'shops/$shopId/gallery/$fileName';
        
        // 진행률 업데이트
        if (onProgress != null) {
          onProgress!((i + 1) / imageFiles.length * 100);
        }
        
        final imageBytes = await imageFile.readAsBytes();
        final response = await _supabaseService.client.storage
            .from(_bucketName)
            .uploadBinary(
              filePath,
              imageBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
        
        if (response.isNotEmpty) {
          final publicUrl = _supabaseService.client.storage
              .from(_bucketName)
              .getPublicUrl(filePath);
          
          uploadedUrls.add(publicUrl);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error uploading gallery image ${i + 1}: $e');
        }
      }
    }
    
    return uploadedUrls;
  }

  // 이미지 삭제
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // URL에서 파일 경로 추출
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // 'storage/v1/object/public/shop-images/' 이후의 경로 추출
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1) return false;
      
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      
      final response = await _supabaseService.client.storage
          .from(_bucketName)
          .remove([filePath]);
      
      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting image: $e');
      }
      return false;
    }
  }

  // 여러 이미지 삭제
  Future<bool> deleteImages(List<String> imageUrls) async {
    try {
      final filePaths = <String>[];
      
      for (final imageUrl in imageUrls) {
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf(_bucketName);
        
        if (bucketIndex != -1) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          filePaths.add(filePath);
        }
      }
      
      if (filePaths.isEmpty) return false;
      
      final response = await _supabaseService.client.storage
          .from(_bucketName)
          .remove(filePaths);
      
      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting multiple images: $e');
      }
      return false;
    }
  }

  // 기존 메인 이미지 삭제
  Future<void> _deleteExistingMainImage(String shopId) async {
    try {
      final folderPath = 'shops/$shopId/main';
      
      final response = await _supabaseService.client.storage
          .from(_bucketName)
          .list(path: folderPath);
      
      if (response.isNotEmpty) {
        final filePaths = response
            .map((file) => '$folderPath/${file.name}')
            .toList();
        
        await _supabaseService.client.storage
            .from(_bucketName)
            .remove(filePaths);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting existing main image: $e');
      }
    }
  }

  // 파일명 생성
  String _generateFileName(String shopId, String prefix, String originalPath) {
    final extension = path.extension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_${timestamp}$extension';
  }

  // 이미지 압축 (옵션)
  Future<Uint8List> _compressImage(Uint8List imageBytes, {int quality = 85}) async {
    // TODO: image 패키지를 사용하여 이미지 압축 구현
    // 현재는 원본 반환
    return imageBytes;
  }

  // 썸네일 생성 (옵션)
  Future<String?> generateThumbnail({
    required String originalUrl,
    required String shopId,
    int width = 300,
    int height = 300,
  }) async {
    // TODO: 썸네일 생성 로직 구현
    // Supabase의 이미지 변환 API 사용 또는 클라이언트 사이드 처리
    return originalUrl;
  }

  // 업로드 가능한 이미지인지 검증
  bool validateImage(XFile file) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = path.extension(file.path).toLowerCase();
    
    if (!validExtensions.contains(extension)) {
      return false;
    }
    
    // 파일 크기 체크 (5MB)
    // file.length()는 비동기이므로 별도 처리 필요
    
    return true;
  }

  // 배치 업로드 with 재시도 로직
  Future<List<String>> batchUploadWithRetry({
    required String shopId,
    required List<XFile> imageFiles,
    int maxRetries = 3,
  }) async {
    final uploadedUrls = <String>[];
    final failedFiles = <XFile>[];
    
    // 첫 번째 시도
    for (final file in imageFiles) {
      final url = await uploadMainImage(shopId: shopId, imageFile: file);
      if (url != null) {
        uploadedUrls.add(url);
      } else {
        failedFiles.add(file);
      }
    }
    
    // 실패한 파일 재시도
    int retryCount = 0;
    while (failedFiles.isNotEmpty && retryCount < maxRetries) {
      retryCount++;
      final retryFiles = List<XFile>.from(failedFiles);
      failedFiles.clear();
      
      for (final file in retryFiles) {
        await Future.delayed(const Duration(seconds: 1)); // 재시도 간격
        final url = await uploadMainImage(shopId: shopId, imageFile: file);
        if (url != null) {
          uploadedUrls.add(url);
        } else {
          failedFiles.add(file);
        }
      }
    }
    
    if (failedFiles.isNotEmpty && kDebugMode) {
      print('Failed to upload ${failedFiles.length} images after $maxRetries retries');
    }
    
    return uploadedUrls;
  }
}