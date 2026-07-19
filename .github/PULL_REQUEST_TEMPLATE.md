## Summary / 概述

<!-- Explain what changed and why. 说明修改内容与原因。 -->

## Verification / 验证

<!-- List manual scenarios and automated tests. 列出手动场景和自动测试。 -->

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze --no-pub`
- [ ] `flutter test --no-pub --no-test-assets --reporter compact`
- [ ] `flutter build apk --debug`

## Checklist / 清单

- [ ] This pull request has one focused purpose. / 此 PR 只处理一个明确主题。
- [ ] Tests cover changed behavior, or I explained why no test is needed. / 已覆盖测试，或已说明无需测试的原因。
- [ ] User-facing documentation is updated in Chinese and English. / 面向用户的中英文文档已同步更新。
- [ ] No secrets, personal media, generated APK/IPA, or private data are included. / 未提交密钥、个人素材、APK/IPA 或私人数据。
- [ ] New third-party media or code includes compatible source and license information. / 新增第三方素材或代码已标明兼容的来源与许可。
- [ ] Android behavior remains supported. / Android 功能保持可用。
- [ ] If this adds or changes iOS support, `flutter build ios --no-codesign` passes and platform gaps are documented. / 如涉及 iOS，无签名构建已通过并记录平台差异。
