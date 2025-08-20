import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import 'shop_edit_screen_v2.dart';
import 'shop_dashboard_screen.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({Key? key}) : super(key: key);

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  final ShopService _shopService = ShopService();
  final AuthService _authService = AuthService();
  
  List<Shop> _myShops = [];
  bool _isLoading = true;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _shopService.setSupabaseMode(true);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // 현재 사용자 프로필 가져오기
      _userProfile = await _authService.getCurrentUserProfile();
      
      if (_userProfile != null) {
        // 내 상점 목록 가져오기
        final shops = await _shopService.getShopsByOwner(_userProfile!.id);
        setState(() {
          _myShops = shops;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로딩 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userProfile == null || _userProfile!.userType != UserType.shopOwner) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('상점 관리'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '상점 관리자만 접근 가능합니다',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                '상점 회원으로 등록하려면 관리자에게 문의하세요',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 상점 관리'),
        backgroundColor: AppColors.primaryPink,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myShops.isEmpty
              ? _buildEmptyState()
              : _buildShopList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewShop,
        backgroundColor: AppColors.primaryPink,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '등록된 상점이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 상점을 등록해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewShop,
            icon: const Icon(Icons.add),
            label: const Text('상점 등록'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myShops.length,
        itemBuilder: (context, index) {
          final shop = _myShops[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _navigateToDashboard(shop),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(shop.imageUrl.isNotEmpty
                                  ? shop.imageUrl
                                  : 'https://via.placeholder.com/150'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getShopTypeColor(shop.shopType),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      shop.shopType.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (shop.isVerified)
                                    const Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.star,
                          shop.ratingText,
                          '평점',
                          Colors.amber,
                        ),
                        _buildStatItem(
                          Icons.rate_review,
                          shop.reviewCount.toString(),
                          '리뷰',
                          Colors.blue,
                        ),
                        _buildStatItem(
                          Icons.favorite,
                          '0', // TODO: 실제 즐겨찾기 수 연동
                          '즐겨찾기',
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _navigateToEdit(shop),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('수정'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToDashboard(shop),
                          icon: const Icon(Icons.dashboard, size: 18),
                          label: const Text('대시보드'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getShopTypeColor(ShopType type) {
    switch (type) {
      case ShopType.offline:
        return Colors.green;
      case ShopType.online:
        return Colors.blue;
      case ShopType.hybrid:
        return Colors.purple;
    }
  }

  void _addNewShop() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('상점 등록 기능은 준비 중입니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToEdit(Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopEditScreenV2(shop: shop),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToDashboard(Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDashboardScreen(shop: shop),
      ),
    );
  }
}