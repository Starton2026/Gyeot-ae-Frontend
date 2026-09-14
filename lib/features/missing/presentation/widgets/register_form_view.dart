import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../data/missing_case.dart';
import '../../data/register_form.dart';
import '../register_draft_providers.dart';
import 'register_body_fields.dart';
import 'register_category_chips.dart';
import 'register_error_text.dart';
import 'register_location_card.dart';
import 'register_missing_at_field.dart';
import 'register_photo_field.dart';
import 'register_police_notice.dart';
import 'register_text_field.dart';

/// 등록 폼(S7) 본문. **읽는 순서가 채우는 순서다**(시안 순서).
///
/// 112 안내 → 사진 → 이름 → 나이·성별 → 구분 → 인상착의 → 위치 → 일시 →
/// 키·몸무게(선택). 이음이는 나오지 않는다(설계 결정 8번).
///
/// 보호자 연락처는 받지 않는다. 제보자에게 공개하지 않고 운영팀이 확인할
/// 수도 없어 쓰는 곳 없이 모으기만 하는 개인정보였다. 제보 소식은 로그인한
/// 계정으로 받는다.
class RegisterFormView extends StatelessWidget {
  const RegisterFormView({
    required this.draft,
    required this.sectionKeys,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onNameChanged,
    required this.onAgeChanged,
    required this.onGenderChanged,
    required this.onCategoryChanged,
    required this.onDescriptionChanged,
    required this.onAdjustLocation,
    required this.onAddressChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onHeightChanged,
    required this.onWeightChanged,
    super.key,
  });

  final RegisterDraft draft;

  /// 칸마다 붙이는 키. 빠진 칸으로 스크롤할 때 화면이 찾는다.
  final Map<RegisterField, GlobalKey> sectionKeys;

  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onAgeChanged;
  final ValueChanged<Gender> onGenderChanged;
  final ValueChanged<MissingCategory> onCategoryChanged;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onAdjustLocation;
  final ValueChanged<String> onAddressChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<String> onHeightChanged;
  final ValueChanged<String> onWeightChanged;

  static const Key nameFieldKey = Key('register_name');
  static const Key ageFieldKey = Key('register_age');
  static const Key genderFieldKey = Key('register_gender');
  static const Key descriptionFieldKey = Key('register_description');
  static const Key addressFieldKey = Key('register_address');
  static const Key heightFieldKey = Key('register_height');
  static const Key weightFieldKey = Key('register_weight');

  /// 고를 수 있는 성별. API에는 `other`도 있지만 실종자 등록에서 고를 일은
  /// 없다고 봤다.
  static const List<Gender> genderChoices = [Gender.male, Gender.female];

  Widget _section(RegisterField field, Widget child) {
    return KeyedSubtree(key: sectionKeys[field], child: child);
  }

  @override
  Widget build(BuildContext context) {
    final form = draft.form;
    final errors = draft.errors;
    const gap = SizedBox(height: 20);

    // ListView로 두지 않는다. 화면 밖 칸을 만들지 않아서, 등록하기를 눌렀을 때
    // 빠진 칸으로 스크롤하려 해도 그 칸을 찾지 못한다. 칸이 열 개 남짓이라
    // 한 번에 다 세워도 부담이 없다.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RegisterPoliceNotice(),
          gap,
          _section(
            RegisterField.photos,
            RegisterPhotoField(
              photoPaths: form.photoPaths,
              canAdd: draft.canAddPhoto,
              onAdd: onAddPhoto,
              onRemove: onRemovePhoto,
              errorText: errors[RegisterField.photos],
            ),
          ),
          gap,
          _section(
            RegisterField.name,
            RegisterTextField(
              fieldKey: nameFieldKey,
              label: '이름',
              required: true,
              value: form.name,
              onChanged: onNameChanged,
              hint: '예) 홍길동',
              errorText: errors[RegisterField.name],
            ),
          ),
          gap,
          _section(
            RegisterField.age,
            KeyedSubtree(
              key: sectionKeys[RegisterField.gender],
              child: _AgeGenderRow(
                age: form.age,
                gender: form.gender,
                onAgeChanged: onAgeChanged,
                onGenderChanged: onGenderChanged,
                ageError: errors[RegisterField.age],
                genderError: errors[RegisterField.gender],
              ),
            ),
          ),
          gap,
          _section(
            RegisterField.category,
            RegisterCategoryChips(
              selected: form.category,
              onSelect: onCategoryChanged,
              errorText: errors[RegisterField.category],
            ),
          ),
          gap,
          _section(
            RegisterField.description,
            RegisterTextField(
              fieldKey: descriptionFieldKey,
              label: '인상착의',
              required: true,
              value: form.description,
              onChanged: onDescriptionChanged,
              hint: '예) 노란 후드티, 검정 백팩',
              help: '옷차림뿐 아니라 습관과 자주 가는 곳도 적어주세요. 옷은 갈아입어도 습관은 남습니다.',
              errorText: errors[RegisterField.description],
              maxLines: 5,
            ),
          ),
          gap,
          _section(
            RegisterField.location,
            RegisterLocationCard(
              hasLocation: form.hasLocation,
              address: form.address,
              addressStatus: draft.addressStatus,
              onAdjust: onAdjustLocation,
              onAddressChanged: onAddressChanged,
              addressFieldKey: addressFieldKey,
              errorText: errors[RegisterField.location],
            ),
          ),
          gap,
          _section(
            RegisterField.missingAt,
            RegisterMissingAtField(
              missingAt: form.missingAt,
              onPickDate: onPickDate,
              onPickTime: onPickTime,
            ),
          ),
          gap,
          RegisterBodyFields(
            height: form.height,
            weight: form.weight,
            onHeightChanged: onHeightChanged,
            onWeightChanged: onWeightChanged,
            heightFieldKey: heightFieldKey,
            weightFieldKey: weightFieldKey,
          ),
        ],
      ),
    );
  }
}

/// 나이 · 성별 한 줄. 두 칸이 반씩 나눈다.
class _AgeGenderRow extends StatelessWidget {
  const _AgeGenderRow({
    required this.age,
    required this.gender,
    required this.onAgeChanged,
    required this.onGenderChanged,
    required this.ageError,
    required this.genderError,
  });

  final String age;
  final Gender? gender;
  final ValueChanged<String> onAgeChanged;
  final ValueChanged<Gender> onGenderChanged;
  final String? ageError;
  final String? genderError;

  static String _label(Gender gender) => switch (gender) {
    Gender.male => '남',
    Gender.female => '여',
    Gender.other => '그 외',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RegisterTextField(
            fieldKey: RegisterFormView.ageFieldKey,
            label: '나이',
            required: true,
            value: age,
            onChanged: onAgeChanged,
            hint: '예) 7',
            suffixText: '세',
            errorText: ageError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FormFieldLabel('성별', required: true),
              const SizedBox(height: 8),
              // 드롭다운은 처음 받은 값을 제 안에 쥔다. 임시저장을 되살려 값이
              // 바뀌면 새로 세워야 칸에 반영된다.
              KeyedSubtree(
                key: ValueKey(gender),
                child: DropdownButtonFormField<Gender>(
                  key: RegisterFormView.genderFieldKey,
                  initialValue: gender,
                  onChanged: (value) {
                    if (value != null) onGenderChanged(value);
                  },
                  hint: Text(
                    '선택',
                    style: AppTextStyles.subtitle1.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textDisabled,
                  ),
                  items: [
                    for (final choice in RegisterFormView.genderChoices)
                      DropdownMenuItem(
                        value: choice,
                        child: Text(_label(choice)),
                      ),
                  ],
                ),
              ),
              RegisterErrorText(genderError),
            ],
          ),
        ),
      ],
    );
  }
}
