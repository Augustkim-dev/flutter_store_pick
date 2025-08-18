import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../theme/app_colors.dart';
import '../screens/auth/login_screen.dart';

class FavoriteButton extends StatefulWidget {
  final String shopId;
  final bool showCount;
  final double size;
  
  const FavoriteButton({
    super.key,
    required this.shopId,
    this.showCount = false,
    this.size = 24,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _favoriteService = FavoriteService();
  
  bool _isFavorite = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    if (_authService.currentUser == null) {
      print('User not logged in - cannot check favorite status');
      return;
    }
    
    print('Checking favorite status for shop: ${widget.shopId}');
    final isFavorite = await _favoriteService.checkFavorite(widget.shopId);
    print('Shop ${widget.shopId} favorite status: $isFavorite');
    
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    print('Toggle favorite for shop: ${widget.shopId}');
    
    // 로그인 체크
    if (_authService.currentUser == null) {
      print('User not logged in');
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그인 필요'),
          content: const Text('즐겨찾기 기능을 사용하려면 로그인이 필요합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('로그인'),
            ),
          ],
        ),
      );
      
      if (result == true && mounted) {
        final loginResult = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
        
        if (loginResult == true) {
          _checkFavoriteStatus();
        }
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 애니메이션 실행
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      
      final success = await _favoriteService.toggleFavorite(widget.shopId);
      print('Toggle result: $success, new state: ${!_isFavorite}');
      
      if (success && mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? '즐겨찾기에 추가되었습니다' : '즐겨찾기에서 제거되었습니다'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite ? Colors.red : AppColors.gray,
          size: widget.size,
        ),
        onPressed: _isLoading ? null : _toggleFavorite,
        splashRadius: widget.size,
      ),
    );
  }
}