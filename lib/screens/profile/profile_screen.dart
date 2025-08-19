import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/favorite_service.dart';
import '../../services/shop_service.dart';
import '../../models/user_profile.dart';
import '../../models/shop.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shop_card.dart';
import '../auth/login_screen.dart';
import '../shop_detail_screen.dart';
import '../debug_screen.dart';
import '../test_favorite_screen.dart';
import '../review_test_screen.dart';
import '../shop/shop_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _favoriteService = FavoriteService();
  final _shopService = ShopService();
  
  late TabController _tabController;
  UserProfile? _userProfile;
  List<Shop> _favoriteShops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 프로필 로드
      final profile = await _authService.getCurrentUserProfile();
      
      // 즐겨찾기 상점 로드
      final favoriteShopData = await _favoriteService.getFavoriteShops();
      final favoriteShops = favoriteShopData
          .map((data) => Shop.fromJson(data))
          .toList();

      setState(() {
        _userProfile = profile;
        _favoriteShops = favoriteShops;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        // 상태 업데이트 (로그인 화면이 자동으로 표시됨)
        setState(() {
          _userProfile = null;
          _favoriteShops = [];
        });
      }
    }
  }

  Widget _buildProfileInfo() {
    if (_userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('프로필 정보를 불러올 수 없습니다'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadUserData,
              child: const Text('다시 시도'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DebugScreen(),
                  ),
                );
              },
              child: const Text('Debug Info'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TestFavoriteScreen(),
                  ),
                );
              },
              child: const Text('Test Favorites'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primaryPink.withAlpha(51),
            child: _userProfile!.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      _userProfile!.avatarUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primaryPink,
                  ),
          ),
          const SizedBox(height: 16),
          
          // 이름
          Text(
            _userProfile!.fullName ?? '이름 없음',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // 이메일
          Text(
            _userProfile!.email ?? _authService.currentUser?.email ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 8),
          
          // 회원 등급
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getUserTypeColor(_userProfile!.userType),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _userProfile!.userType.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // 통계
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('즐겨찾기', '${_favoriteShops.length}'),
              _buildStatItem('리뷰', '0'), // TODO: 리뷰 개수 구현
              _buildStatItem('가입일', _formatDate(_userProfile!.createdAt)),
            ],
          ),
          const SizedBox(height: 32),
          
          // 메뉴 리스트
          if (_userProfile!.userType == UserType.shopOwner) ...[
            _buildMenuItem(
              icon: Icons.store,
              title: '내 상점 관리',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ShopManagementScreen(),
                  ),
                );
              },
            ),
            const Divider(),
          ],
          _buildMenuItem(
            icon: Icons.person_outline,
            title: '프로필 수정',
            onTap: () {
              // TODO: 프로필 수정 화면으로 이동
            },
          ),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: '비밀번호 변경',
            onTap: () {
              // TODO: 비밀번호 변경 화면으로 이동
            },
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: '알림 설정',
            onTap: () {
              // TODO: 알림 설정 화면으로 이동
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: '도움말',
            onTap: () {
              // TODO: 도움말 화면으로 이동
            },
          ),
          _buildMenuItem(
            icon: Icons.bug_report,
            title: 'Debug Info',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DebugScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.science,
            title: 'Test Favorites',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TestFavoriteScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.rate_review,
            title: 'Test Reviews',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReviewTestScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: '로그아웃',
            onTap: _signOut,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.gray,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildFavoriteShops() {
    if (_favoriteShops.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.gray,
            ),
            SizedBox(height: 16),
            Text(
              '즐겨찾기한 상점이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteShops.length,
        itemBuilder: (context, index) {
          final shop = _favoriteShops[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Dismissible(
              key: Key(shop.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('즐겨찾기 삭제'),
                    content: Text('${shop.name}을(를) 즐겨찾기에서 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                await _favoriteService.removeFavorite(shop.id);
                await _loadUserData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${shop.name}이(가) 즐겨찾기에서 삭제되었습니다'),
                    ),
                  );
                }
              },
              child: ShopCard(
                shop: shop,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ShopDetailScreen(shop: shop),
                    ),
                  );
                  // 상세 화면에서 돌아온 후 즐겨찾기 목록 새로고침
                  _loadUserData();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.purple;
      case UserType.shopOwner:
        return Colors.blue;
      case UserType.general:
      default:
        return AppColors.primaryPink;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 로그인하지 않은 경우
    if (_authService.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('마이페이지'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.gray,
              ),
              const SizedBox(height: 16),
              const Text(
                '로그인이 필요합니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '로그인하고 더 많은 기능을 이용하세요',
                style: TextStyle(
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                  
                  if (result == true && mounted) {
                    // 로그인 성공 시 프로필 데이터 새로고침
                    await _loadUserData();
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  '로그인',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 로그인한 경우
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '프로필'),
            Tab(text: '즐겨찾기'),
          ],
          indicatorColor: AppColors.primaryPink,
          labelColor: AppColors.primaryPink,
          unselectedLabelColor: AppColors.gray,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileInfo(),
                _buildFavoriteShops(),
              ],
            ),
    );
  }
}