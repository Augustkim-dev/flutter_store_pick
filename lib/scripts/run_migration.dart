import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

Future<void> main() async {
  print('Starting database migration...');
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dzfkgfdwskbindpmlbum.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR6ZmtnZmR3c2tiaW5kcG1sYnVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzOTkwNDQsImV4cCI6MjA3MDk3NTA0NH0.letbe1mHeSbLSDvovjpA7QmurVMxPclhJeHYRnBJ24U',
  );

  
  // Read migration file
  final migrationFile = File('supabase/migrations/20250120_shop_manager_phase1.sql');
  if (!migrationFile.existsSync()) {
    print('Migration file not found!');
    exit(1);
  }
  
  final sql = await migrationFile.readAsString();
  
  // Split SQL into individual statements (simple approach)
  // Note: This is a simplified version. In production, you'd need a proper SQL parser
  final statements = sql.split(';')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty && !s.startsWith('--'))
    .toList();
  
  print('Found ${statements.length} SQL statements to execute');
  
  int successCount = 0;
  int errorCount = 0;
  
  for (int i = 0; i < statements.length; i++) {
    final statement = statements[i];
    
    // Skip comments and empty statements
    if (statement.isEmpty || statement.startsWith('--')) {
      continue;
    }
    
    try {
      print('\nExecuting statement ${i + 1}/${statements.length}...');
      
      // For complex statements like CREATE TABLE, CREATE VIEW, etc.
      // We need to use RPC or direct SQL execution
      // Since Supabase Dart SDK doesn't support direct SQL execution,
      // we'll need to use the SQL editor in Supabase Dashboard
      
      print('Statement preview: ${statement.substring(0, statement.length > 50 ? 50 : statement.length)}...');
      
      // Note: This won't actually execute the SQL since Supabase Dart SDK
      // doesn't have a direct SQL execution method
      print('⚠️  Please execute this statement in Supabase SQL Editor');
      
      successCount++;
    } catch (e) {
      print('Error executing statement ${i + 1}: $e');
      errorCount++;
    }
  }
  
  print('\n' + '=' * 50);
  print('Migration Summary:');
  print('Total statements: ${statements.length}');
  print('Successful: $successCount');
  print('Errors: $errorCount');
  print('=' * 50);
  
  print('\n⚠️  IMPORTANT: The Supabase Dart SDK does not support direct SQL execution.');
  print('Please copy the migration SQL file and execute it in the Supabase Dashboard:');
  print('1. Go to https://supabase.com/dashboard/project/dzfkgfdwskbindpmlbum/sql/new');
  print('2. Copy the contents of supabase/migrations/20250120_shop_manager_phase1.sql');
  print('3. Paste and execute in the SQL editor');
  
  exit(0);
}