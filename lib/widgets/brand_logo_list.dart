import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BrandLogoList extends StatelessWidget {
  final List<String> brands;

  const BrandLogoList({
    Key? key,
    required this.brands,
  }) : super(key: key);

  // 브랜드별 로고 URL (실제로는 API나 assets에서 가져와야 함)
  String? _getBrandLogoUrl(String brand) {
    // TODO: 실제 브랜드 로고 URL 매핑
    final brandLogos = {
      'Repetto': 'https://example.com/repetto-logo.png',
      'Capezio': 'https://example.com/capezio-logo.png',
      'Bloch': 'https://example.com/bloch-logo.png',
      'Gaynor Minden': 'https://example.com/gaynor-logo.png',
      'Wear Moi': 'https://example.com/wearmoi-logo.png',
      'Chacott': 'https://example.com/chacott-logo.png',
    };
    return brandLogos[brand];
  }

  // 브랜드별 배경색상
  Color _getBrandColor(String brand) {
    // 브랜드명의 해시코드를 사용하여 일관된 색상 생성
    final colors = [
      AppColors.primaryPink.withOpacity(0.1),
      AppColors.secondaryPurple.withOpacity(0.1),
      AppColors.secondaryAccent.withOpacity(0.1),
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.orange.shade50,
    ];
    return colors[brand.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          final logoUrl = _getBrandLogoUrl(brand);
          
          return Container(
            width: 100,
            margin: EdgeInsets.only(
              right: index < brands.length - 1 ? 12 : 0,
            ),
            decoration: BoxDecoration(
              color: _getBrandColor(brand),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: logoUrl != null
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildBrandText(brand);
                      },
                    ),
                  )
                : _buildBrandText(brand),
          );
        },
      ),
    );
  }

  Widget _buildBrandText(String brand) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          brand,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}