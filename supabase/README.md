# Supabase 설정 가이드

## 1. 테이블 생성
`schema.sql` 파일을 Supabase SQL Editor에서 실행하여 테이블을 생성합니다.

## 2. 초기 데이터 삽입
`seed.sql` 파일을 실행하여 샘플 데이터를 추가합니다.

## 3. 앱 연동 확인
- 앱 실행 시 Supabase 초기화 메시지 확인
- 홈 화면에서 실제 데이터가 로드되는지 확인
- 더미 데이터 모드로 폴백되는 경우 Supabase 설정 재확인

## 4. 환경 설정
`lib/config/supabase_config.dart`에서 Supabase URL과 anon key를 확인하세요.

## 5. Row Level Security (RLS)
현재 읽기 권한은 모든 사용자에게 열려있습니다.
인증 기능 구현 시 RLS 정책을 업데이트해야 합니다.