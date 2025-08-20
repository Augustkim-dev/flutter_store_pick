# Firebase 설정 가이드

## 1. Firebase Console에서 앱 추가하기

### Android 앱 추가
1. [Firebase Console](https://console.firebase.google.com/)에서 `balletplus-519b5` 프로젝트 열기
2. 프로젝트 개요 페이지에서 "앱 추가" 클릭
3. Android 아이콘 선택
4. 다음 정보 입력:
   - Android 패키지 이름: `com.accu.balletPlus`
   - 앱 닉네임: `발레플러스 Android`
   - 디버그 서명 인증서 SHA-1: (선택사항, 나중에 추가 가능)
5. `google-services.json` 다운로드
6. 다운로드한 파일을 `android/app/` 폴더에 복사

### iOS 앱 추가
1. Firebase Console에서 "앱 추가" 클릭
2. iOS 아이콘 선택
3. 다음 정보 입력:
   - iOS 번들 ID: `com.accu.balletPlus`
   - 앱 닉네임: `발레플러스 iOS`
   - App Store ID: (선택사항)
4. `GoogleService-Info.plist` 다운로드
5. 다운로드한 파일을 `ios/Runner/` 폴더에 복사

## 2. Android 빌드 설정 업데이트

### android/build.gradle
프로젝트 레벨 build.gradle에 다음 추가:
```gradle
buildscript {
    dependencies {
        // 기존 dependencies...
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### android/app/build.gradle
앱 레벨 build.gradle에 다음 추가:
```gradle
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        minSdkVersion 21  // Firebase는 최소 API 21 필요
    }
}
```

## 3. iOS 빌드 설정 업데이트

### ios/Runner.xcodeproj
1. Xcode에서 프로젝트 열기
2. Runner 타겟 선택
3. Build Phases 탭에서:
   - "+" 버튼 클릭 → "New Run Script Phase" 추가
   - 다음 스크립트 추가:
   ```bash
   "${PODS_ROOT}/FirebaseCrashlytics/run"
   ```

### ios/Podfile
플랫폼 버전 확인:
```ruby
platform :ios, '12.0'  # Firebase는 최소 iOS 12.0 필요
```

## 4. Remote Config 설정

### Firebase Console에서:
1. 왼쪽 메뉴에서 "Remote Config" 선택
2. "구성 만들기" 클릭
3. 다음 매개변수 추가:

| 매개변수 키 | 기본값 | 설명 |
|------------|--------|------|
| minimum_version | 1.0.0 | 최소 필수 버전 |
| latest_version | 1.0.0 | 최신 버전 |
| force_update | false | 강제 업데이트 여부 |
| update_url_android | https://play.google.com/store/apps/details?id=com.accu.balletPlus | Android 업데이트 URL |
| update_url_ios | https://apps.apple.com/app/idYOURAPPID | iOS 업데이트 URL |
| update_message | 새로운 버전이 출시되었습니다! 업데이트하여 최신 기능을 사용해보세요. | 업데이트 메시지 |
| maintenance_mode | false | 서버 점검 모드 |
| maintenance_message | 서버 점검 중입니다. 잠시 후 다시 시도해주세요. | 점검 메시지 |

4. "게시" 클릭하여 설정 활성화

## 5. 실제 API 키 업데이트

`lib/firebase_options.dart` 파일의 플레이스홀더를 실제 값으로 교체:
- Firebase Console → 프로젝트 설정 → 일반 탭에서 각 플랫폼별 설정 정보 확인
- 각 플랫폼의 API 키와 앱 ID를 복사하여 교체

## 6. 테스트

### 버전 업데이트 테스트:
1. Remote Config에서 `latest_version`을 `1.1.0`으로 변경
2. `force_update`를 `true`로 설정
3. "게시" 클릭
4. 앱 재시작하여 업데이트 다이얼로그 확인

### 서버 점검 테스트:
1. Remote Config에서 `maintenance_mode`를 `true`로 설정
2. "게시" 클릭
3. 앱 재시작하여 점검 다이얼로그 확인

## 주의사항
- google-services.json과 GoogleService-Info.plist 파일은 .gitignore에 추가하여 버전 관리에서 제외
- 프로덕션 배포 전 실제 스토어 URL로 업데이트
- 버전 번호는 pubspec.yaml의 version과 동기화