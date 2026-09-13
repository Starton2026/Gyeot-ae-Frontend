import 'package:gyeotae/features/missing/data/register_draft_storage.dart';
import 'package:gyeotae/features/missing/data/register_form.dart';

/// 등록 폼 임시저장을 메모리에만 담는다.
class InMemoryRegisterDraftStorage implements RegisterDraftStorage {
  InMemoryRegisterDraftStorage([this.saved]);

  RegisterForm? saved;

  @override
  Future<RegisterForm?> load() async => saved;

  @override
  Future<void> save(RegisterForm form) async => saved = form;

  @override
  Future<void> clear() async => saved = null;
}
