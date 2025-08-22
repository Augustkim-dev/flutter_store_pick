import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/shop.dart';
import '../services/shop_service.dart';
import '../theme/app_colors.dart';
import 'shop_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ShopService _shopService = ShopService();
  NaverMapController? _mapController;
  
  List<Shop> _offlineShops = [];
  Position? _currentPosition;
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  
  // 서울 중심 기본 위치
  static const NLatLng _defaultLocation = NLatLng(37.5665, 126.9780);
  
  @override
  void initState() {
    super.initState();
    _shopService.setSupabaseMode(true);
    _initializeMap();
  }
  
  Future<void> _initializeMap() async {
    await _checkLocationPermission();
    await _getCurrentLocation();
    await _loadOfflineShops();
  }
  
  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationPermissionGranted = status == PermissionStatus.granted;
    });
  }
  
  Future<void> _getCurrentLocation() async {
    if (!_locationPermissionGranted) return;
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      
      // 네이버 지도의 기본 위치 추적 기능이 자동으로 처리
    } catch (e) {
      debugPrint('위치 가져오기 실패: $e');
    }
  }
  
  
  Future<void> _loadOfflineShops() async {
    try {
      final shops = await _shopService.getAllShops();
      // 오프라인 또는 하이브리드 매장만 필터링
      final offlineShops = shops.where((shop) => shop.isOffline).toList();
      
      setState(() {
        _offlineShops = offlineShops;
        _isLoading = false;
      });
      
      // 마커 추가
      if (_mapController != null) {
        _addMarkers();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('매장 로딩 실패: $e');
    }
  }
  
  void _addMarkers() {
    if (_mapController == null) return;
    
    for (final shop in _offlineShops) {
      if (shop.latitude != null && shop.longitude != null) {
        final marker = NMarker(
          id: shop.id,
          position: NLatLng(shop.latitude!, shop.longitude!),
          caption: NOverlayCaption(
            text: shop.name,
            textSize: 14,
          ),
        );
        
        // 마커 색상 설정 (오프라인/하이브리드 구분)
        // 기본 마커 사용 (커스텀 이미지는 assets 폴더에 추가 필요)
        
        // 마커 클릭 리스너
        marker.setOnTapListener((overlay) {
          _showShopBottomSheet(shop);
        });
        
        _mapController!.addOverlay(marker);
      }
    }
  }
  
  void _showShopBottomSheet(Shop shop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // 거리 계산
        String distanceText = '';
        if (_currentPosition != null && shop.latitude != null && shop.longitude != null) {
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            shop.latitude!,
            shop.longitude!,
          );
          
          if (distance < 1000) {
            distanceText = '${distance.toStringAsFixed(0)}m';
          } else {
            distanceText = '${(distance / 1000).toStringAsFixed(1)}km';
          }
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상점 타입 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: shop.shopType == ShopType.offline 
                    ? AppColors.offlineShop 
                    : AppColors.secondaryAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  shop.shopType.displayName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // 상점명
              Text(
                shop.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              
              // 평점
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.warning, size: 20),
                  const SizedBox(width: 4),
                  Text(shop.ratingText),
                  Text(' (${shop.reviewCount}개)'),
                  if (distanceText.isNotEmpty) ...[
                    const Spacer(),
                    Icon(Icons.location_on, color: AppColors.gray, size: 20),
                    const SizedBox(width: 4),
                    Text(distanceText),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              
              // 주소
              if (shop.address != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place, color: AppColors.gray, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shop.address!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // 영업시간
              if (shop.businessHours != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.access_time, color: AppColors.gray, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shop.businessHours!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // 상세보기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ShopDetailScreen(shop: shop),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '상세보기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매장 지도'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _locationPermissionGranted ? Icons.my_location : Icons.location_disabled,
              color: _locationPermissionGranted ? AppColors.primaryPink : AppColors.gray,
            ),
            onPressed: () async {
              if (!_locationPermissionGranted) {
                await _checkLocationPermission();
                if (_locationPermissionGranted && _mapController != null) {
                  // 위치 권한 획득 후 위치 추적 모드 활성화
                  _mapController!.setLocationTrackingMode(NLocationTrackingMode.follow);
                }
              } else {
                await _getCurrentLocation();
                if (_currentPosition != null && _mapController != null) {
                  // 현재 위치로 카메라 이동
                  final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
                    target: NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 15,
                  );
                  cameraUpdate.setAnimation(
                    animation: NCameraAnimation.fly,
                    duration: const Duration(seconds: 1),
                  );
                  _mapController!.updateCamera(cameraUpdate);
                  // 위치 추적 모드 재활성화
                  _mapController!.setLocationTrackingMode(NLocationTrackingMode.follow);
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 네이버 지도
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: _currentPosition != null
                  ? NLatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _defaultLocation,
                zoom: 14,
              ),
              mapType: NMapType.basic,
              activeLayerGroups: [NLayerGroup.building, NLayerGroup.transit],
              extent: const NLatLngBounds(
                southWest: NLatLng(33.0, 124.0), // 한국 영역
                northEast: NLatLng(44.0, 132.0),
              ),
              minZoom: 5,
              maxZoom: 18,
              locale: const Locale('ko', 'KR'),
              // 줌 컨트롤 표시
              zoomGesturesEnable: true,
              scrollGesturesEnable: true,
              tiltGesturesEnable: true,
              rotationGesturesEnable: true,
              // UI 컨트롤 설정
              locationButtonEnable: false, // 커스텀 위치 버튼 사용
              scaleBarEnable: true, // 축척 바 표시
              indoorLevelPickerEnable: true, // 실내 층 선택기
              logoClickEnable: true, // 네이버 로고 클릭 가능
            ),
            onMapReady: (controller) {
              _mapController = controller;
              _addMarkers();
              
              // 위치 권한이 있으면 위치 추적 모드 활성화
              if (_locationPermissionGranted && _currentPosition != null) {
                // 네이버 지도 기본 위치 오버레이 사용
                controller.setLocationTrackingMode(NLocationTrackingMode.follow);
              }
            },
          ),
          
          // 로딩 인디케이터
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // 오프라인 매장 수 표시
          if (!_isLoading && _offlineShops.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store, size: 16, color: AppColors.primaryPink),
                    const SizedBox(width: 6),
                    Text(
                      '오프라인 매장 ${_offlineShops.length}개',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // 줌 컨트롤 버튼
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                // 줌 인 버튼
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (_mapController != null) {
                          final cameraUpdate = NCameraUpdate.zoomIn();
                          _mapController!.updateCamera(cameraUpdate);
                        }
                      },
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.add, size: 24, color: AppColors.gray),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  width: 48,
                  color: AppColors.gray.withAlpha(51),
                ),
                // 줌 아웃 버튼
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (_mapController != null) {
                          final cameraUpdate = NCameraUpdate.zoomOut();
                          _mapController!.updateCamera(cameraUpdate);
                        }
                      },
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.remove, size: 24, color: AppColors.gray),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}