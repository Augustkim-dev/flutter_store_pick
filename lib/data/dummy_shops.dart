import '../models/shop.dart';

class DummyShops {
  static final List<Shop> shops = [
    // 오프라인 매장들
    Shop(
      id: '1',
      name: '발레리나 하우스',
      shopType: ShopType.offline,
      description: '강남구 최대 규모의 발레 용품 전문점입니다. 다양한 브랜드와 사이즈를 보유하고 있습니다.',
      brands: ['Repetto', 'Bloch', 'Capezio', 'Grishko', 'Wear Moi'],
      rating: 4.8,
      reviewCount: 234,
      imageUrl: 'https://picsum.photos/400/300?random=1',
      address: '서울특별시 강남구 신사동 123-45',
      phone: '02-1234-5678',
      latitude: 37.5172,
      longitude: 127.0473,
      businessHours: '평일 10:00-20:00, 주말 11:00-19:00',
      parkingAvailable: true,
      fittingAvailable: true,
      categories: ['토슈즈', '레오타드', '타이즈', '워머', '가방'],
      isVerified: true,
    ),
    
    Shop(
      id: '2',
      name: '댄스마트 대학로점',
      shopType: ShopType.offline,
      description: '무용 전공생들이 가장 많이 찾는 대학로 발레 용품점',
      brands: ['Sansha', 'So Danca', 'Body Wrappers', 'Mirella'],
      rating: 4.6,
      reviewCount: 189,
      imageUrl: 'https://picsum.photos/400/300?random=2',
      address: '서울특별시 종로구 대학로 87',
      phone: '02-9876-5432',
      latitude: 37.5827,
      longitude: 127.0037,
      businessHours: '매일 09:00-21:00',
      parkingAvailable: false,
      fittingAvailable: true,
      categories: ['토슈즈', '레오타드', '연습복', '액세서리'],
      isVerified: true,
    ),
    
    Shop(
      id: '3',
      name: '핑크튜튜',
      shopType: ShopType.offline,
      description: '어린이 발레 용품 전문점. 키즈 사이즈 다양하게 구비',
      brands: ['Capezio Kids', 'Dansco', 'Bloch Kids'],
      rating: 4.9,
      reviewCount: 156,
      imageUrl: 'https://picsum.photos/400/300?random=3',
      address: '서울특별시 송파구 잠실동 22-3',
      phone: '02-424-8888',
      latitude: 37.5145,
      longitude: 127.1003,
      businessHours: '화-일 10:00-19:00 (월요일 휴무)',
      parkingAvailable: true,
      fittingAvailable: true,
      categories: ['키즈 레오타드', '키즈 토슈즈', '튜튜 드레스'],
      isVerified: false,
    ),
    
    // 온라인 쇼핑몰들
    Shop(
      id: '4',
      name: '발레몰',
      shopType: ShopType.online,
      description: '국내 최대 발레 용품 온라인 쇼핑몰. 24시간 주문 가능',
      brands: ['Repetto', 'Gaynor Minden', 'Russian Pointe', 'Freed', 'Grishko'],
      rating: 4.5,
      reviewCount: 892,
      imageUrl: 'https://picsum.photos/400/300?random=4',
      websiteUrl: 'https://www.balletmall.co.kr',
      phone: '1588-1234',
      shippingFee: 3000,
      freeShippingMin: 50000,
      deliveryInfo: '평균 2-3일 소요, 당일배송 가능(서울/경기)',
      categories: ['토슈즈', '레오타드', '타이즈', '워머', '가방', '액세서리'],
      isVerified: true,
    ),
    
    Shop(
      id: '5',
      name: '댄스코리아',
      shopType: ShopType.online,
      description: '발레, 현대무용, 재즈댄스 용품 종합 쇼핑몰',
      brands: ['Wear Moi', 'Intermezzo', 'Temps Danse', 'Ballet Rosa'],
      rating: 4.3,
      reviewCount: 567,
      imageUrl: 'https://picsum.photos/400/300?random=5',
      websiteUrl: 'https://www.dancekorea.com',
      phone: '1577-8282',
      shippingFee: 2500,
      freeShippingMin: 30000,
      deliveryInfo: '평균 3-5일 소요',
      categories: ['레오타드', '타이즈', '연습복', '무용화'],
      isVerified: true,
    ),
    
    Shop(
      id: '6',
      name: '발레리노샵',
      shopType: ShopType.online,
      description: '수입 브랜드 전문 온라인 편집샵',
      brands: ['Yumiko', 'Eleve', 'Lucky Leo', 'Cloud & Victory'],
      rating: 4.7,
      reviewCount: 234,
      imageUrl: 'https://picsum.photos/400/300?random=6',
      websiteUrl: 'https://www.ballerinoshop.kr',
      phone: '02-3333-4444',
      shippingFee: 5000,
      freeShippingMin: 100000,
      deliveryInfo: '평균 5-7일 소요 (해외직구 상품 2-3주)',
      categories: ['수입 레오타드', '디자이너 브랜드', '커스텀 의상'],
      isVerified: false,
    ),
    
    // 하이브리드 (온/오프라인)
    Shop(
      id: '7',
      name: '그리쉬코 코리아',
      shopType: ShopType.hybrid,
      description: 'Grishko 공식 수입사. 온라인몰과 쇼룸 운영',
      brands: ['Grishko', 'Grishko Pro', 'Nikolay'],
      rating: 4.9,
      reviewCount: 445,
      imageUrl: 'https://picsum.photos/400/300?random=7',
      address: '서울특별시 강남구 청담동 45-12',
      phone: '02-543-7890',
      latitude: 37.5197,
      longitude: 127.0474,
      businessHours: '평일 11:00-19:00 (예약제)',
      parkingAvailable: true,
      fittingAvailable: true,
      websiteUrl: 'https://www.grishko.co.kr',
      shippingFee: 0,
      freeShippingMin: 0,
      deliveryInfo: '전 상품 무료배송',
      categories: ['토슈즈', '포인트슈즈', '레오타드', '전문가용품'],
      isVerified: true,
    ),
    
    Shop(
      id: '8',
      name: '블로흐 부산',
      shopType: ShopType.offline,
      description: '부산 지역 최대 발레 용품점. Bloch 공식 딜러',
      brands: ['Bloch', 'Bloch Pro', 'Mirella', 'Leo'],
      rating: 4.5,
      reviewCount: 178,
      imageUrl: 'https://picsum.photos/400/300?random=8',
      address: '부산광역시 해운대구 중동 1234',
      phone: '051-747-9999',
      latitude: 35.1628,
      longitude: 129.1639,
      businessHours: '매일 10:00-20:00',
      parkingAvailable: true,
      fittingAvailable: true,
      categories: ['토슈즈', '레오타드', '타이즈', '재즈슈즈'],
      isVerified: true,
    ),
    
    Shop(
      id: '9',
      name: '튜튜앤레오',
      shopType: ShopType.online,
      description: '합리적인 가격의 입문자용 발레 용품 전문',
      brands: ['Body Wrappers', 'Danznmotion', 'Motionwear'],
      rating: 4.2,
      reviewCount: 334,
      imageUrl: 'https://picsum.photos/400/300?random=9',
      websiteUrl: 'https://www.tutuleo.com',
      phone: '070-8888-1234',
      shippingFee: 2500,
      freeShippingMin: 25000,
      deliveryInfo: '평균 2-3일 소요',
      categories: ['입문자용품', '레오타드', '타이즈', '슈즈'],
      isVerified: false,
    ),
    
    Shop(
      id: '10',
      name: '아라베스크',
      shopType: ShopType.offline,
      description: '20년 전통의 발레 용품 전문점',
      brands: ['Capezio', 'Sansha', 'Freed', 'Suffolk'],
      rating: 4.6,
      reviewCount: 423,
      imageUrl: 'https://picsum.photos/400/300?random=10',
      address: '서울특별시 서초구 서초동 1650-3',
      phone: '02-3473-1234',
      latitude: 37.4967,
      longitude: 127.0276,
      businessHours: '평일 10:00-19:00, 토요일 10:00-17:00 (일요일 휴무)',
      parkingAvailable: false,
      fittingAvailable: true,
      categories: ['토슈즈', '레오타드', '전문가용품', '무대의상'],
      isVerified: true,
    ),
    
    Shop(
      id: '11',
      name: '발레스타',
      shopType: ShopType.hybrid,
      description: '온라인 주문 후 매장 픽업 가능. 맞춤 의상 제작',
      brands: ['Custom Made', 'Wear Moi', 'Intermezzo'],
      rating: 4.8,
      reviewCount: 267,
      imageUrl: 'https://picsum.photos/400/300?random=11',
      address: '서울특별시 마포구 상수동 72-1',
      phone: '02-322-5678',
      latitude: 37.5478,
      longitude: 126.9227,
      businessHours: '화-토 11:00-20:00',
      parkingAvailable: false,
      fittingAvailable: true,
      websiteUrl: 'https://www.balletstar.kr',
      shippingFee: 3000,
      freeShippingMin: 40000,
      deliveryInfo: '맞춤제작 2-3주 소요',
      categories: ['맞춤의상', '무대의상', '레오타드', '튜튜'],
      isVerified: false,
    ),
    
    Shop(
      id: '12',
      name: '리틀발레리나',
      shopType: ShopType.online,
      description: '유아 및 어린이 발레 용품 전문 온라인몰',
      brands: ['Capezio Kids', 'Bloch Kids', 'Dansco Kids'],
      rating: 4.9,
      reviewCount: 445,
      imageUrl: 'https://picsum.photos/400/300?random=12',
      websiteUrl: 'https://www.littleballerina.co.kr',
      phone: '1599-8282',
      shippingFee: 2500,
      freeShippingMin: 20000,
      deliveryInfo: '평균 1-2일 소요',
      categories: ['키즈레오타드', '키즈슈즈', '키즈타이즈', '헤어액세서리'],
      isVerified: true,
    ),
  ];
  
  // 상점 유형별 필터링
  static List<Shop> get offlineShops => 
    shops.where((shop) => shop.isOffline).toList();
  
  static List<Shop> get onlineShops => 
    shops.where((shop) => shop.isOnline).toList();
  
  // ID로 상점 찾기
  static Shop? getShopById(String id) {
    try {
      return shops.firstWhere((shop) => shop.id == id);
    } catch (_) {
      return null;
    }
  }
  
  // 브랜드로 상점 검색
  static List<Shop> searchByBrand(String brand) {
    return shops.where((shop) => 
      shop.brands.any((b) => b.toLowerCase().contains(brand.toLowerCase()))
    ).toList();
  }
}