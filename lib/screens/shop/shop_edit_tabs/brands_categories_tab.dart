import 'package:flutter/material.dart';
import '../../../models/shop.dart';
import '../../../models/brand.dart';
import '../../../models/shop_category.dart';
import '../../../services/brand_service.dart';
import '../../../theme/app_colors.dart';

class BrandsCategoriesTab extends StatefulWidget {
  final Shop shop;
  final List<Brand> selectedBrands;
  final List<String> selectedCategories;
  final ValueChanged<List<Brand>> onBrandsChanged;
  final ValueChanged<List<String>> onCategoriesChanged;

  const BrandsCategoriesTab({
    Key? key,
    required this.shop,
    required this.selectedBrands,
    required this.selectedCategories,
    required this.onBrandsChanged,
    required this.onCategoriesChanged,
  }) : super(key: key);

  @override
  State<BrandsCategoriesTab> createState() => _BrandsCategoriesTabState();
}

class _BrandsCategoriesTabState extends State<BrandsCategoriesTab> {
  final BrandService _brandService = BrandService();
  final TextEditingController _brandSearchController = TextEditingController();
  List<Brand> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _brandSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchBrands(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _brandService.searchBrands(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _addBrand(Brand brand) {
    if (!widget.selectedBrands.any((b) => b.id == brand.id)) {
      final updatedBrands = List<Brand>.from(widget.selectedBrands)..add(brand);
      widget.onBrandsChanged(updatedBrands);
      _brandSearchController.clear();
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _removeBrand(Brand brand) {
    final updatedBrands = widget.selectedBrands.where((b) => b.id != brand.id).toList();
    widget.onBrandsChanged(updatedBrands);
  }

  void _toggleCategory(String category) {
    final updatedCategories = List<String>.from(widget.selectedCategories);
    if (updatedCategories.contains(category)) {
      updatedCategories.remove(category);
    } else {
      updatedCategories.add(category);
    }
    widget.onCategoriesChanged(updatedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 브랜드 관리
          _buildSectionTitle('취급 브랜드'),
          const SizedBox(height: 12),
          
          // 브랜드 검색
          TextField(
            controller: _brandSearchController,
            decoration: InputDecoration(
              labelText: '브랜드 검색',
              hintText: '브랜드명을 입력하세요',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _brandSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _brandSearchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
            ),
            onChanged: (value) => _searchBrands(value),
          ),
          
          // 검색 결과
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final brand = _searchResults[index];
                  final isSelected = widget.selectedBrands.any((b) => b.id == brand.id);
                  return ListTile(
                    leading: brand.logoUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(brand.logoUrl!),
                            backgroundColor: Colors.grey.shade200,
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: Text(brand.name[0].toUpperCase()),
                          ),
                    title: Text(brand.name),
                    subtitle: brand.description != null
                        ? Text(
                            brand.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primaryPink)
                        : const Icon(Icons.add_circle_outline),
                    onTap: isSelected ? null : () => _addBrand(brand),
                  );
                },
              ),
            ),
          ],
          
          // 선택된 브랜드
          const SizedBox(height: 16),
          if (widget.selectedBrands.isNotEmpty) ...[
            Text(
              '선택된 브랜드 (${widget.selectedBrands.length}개)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedBrands.map((brand) {
                return Chip(
                  label: Text(brand.name),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeBrand(brand),
                  backgroundColor: AppColors.secondaryPurple.withOpacity(0.1),
                  deleteIconColor: AppColors.secondaryPurple,
                );
              }).toList(),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '취급 브랜드를 검색하여 추가하세요',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),

          // 카테고리 관리
          _buildSectionTitle('취급 카테고리'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '판매하는 상품 카테고리를 선택하세요',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ShopCategory.defaultCategories.map((category) {
                      final isSelected = widget.selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => _toggleCategory(category),
                        selectedColor: AppColors.primaryPink.withOpacity(0.2),
                        checkmarkColor: AppColors.primaryPink,
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 전문 카테고리 설정
          if (widget.selectedCategories.isNotEmpty) ...[
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '전문 카테고리',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '특히 전문적으로 취급하는 카테고리가 있다면 선택하세요.\n'
                      '검색 결과에서 우선 노출됩니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.selectedCategories.map((category) {
                        // TODO: 전문 카테고리 설정 기능 구현
                        return OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$category를 전문 카테고리로 설정'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.star_outline, size: 16),
                          label: Text(category),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade700,
                            side: BorderSide(color: Colors.amber.shade700),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        );
                      }).toList(),
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
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 20,
                  color: Colors.purple.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '브랜드 & 카테고리 관리 Tip',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• 정확한 브랜드 정보는 검색 노출을 높입니다\n'
                        '• 다양한 카테고리는 더 많은 고객을 유치합니다\n'
                        '• 전문 카테고리 설정으로 차별화하세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade700,
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