import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_form.dart';

/// 등록 폼 임시저장(F-7.11). **이 기기에만** 남는다.
///
/// 한 사람이 동시에 두 건을 쓰는 일은 없다고 보고 한 칸만 둔다. 등록에
/// 성공하면 지운다.
abstract interface class RegisterDraftStorage {
  /// 저장한 폼. 없거나 읽을 수 없으면 null.
  Future<RegisterForm?> load();

  Future<void> save(RegisterForm form);

  Future<void> clear();
}

class PrefsRegisterDraftStorage implements RegisterDraftStorage {
  PrefsRegisterDraftStorage({bool Function(String path)? fileExists})
    : _fileExists = fileExists ?? _defaultFileExists;

  static const _key = 'register_draft';

  /// 사진 파일이 아직 있는가. 테스트에서 갈아끼운다.
  final bool Function(String path) _fileExists;

  static bool _defaultFileExists(String path) => File(path).existsSync();

  @override
  Future<RegisterForm?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;

      final form = RegisterForm.fromJson(json);

      // image_picker가 준 경로는 캐시라 그사이 OS가 치웠을 수 있다. 없는
      // 파일을 붙여 보내면 등록이 통째로 실패하니, 없어진 사진만 뺀다.
      return form.copyWith(
        photoPaths: form.photoPaths.where(_fileExists).toList(growable: false),
      );
    } on FormatException catch (error) {
      debugPrint('[임시저장] 읽지 못해 버린다: $error');
      return null;
    }
  }

  @override
  Future<void> save(RegisterForm form) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(form.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final registerDraftStorageProvider = Provider<RegisterDraftStorage>((ref) {
  return PrefsRegisterDraftStorage();
});
