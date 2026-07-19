# Contributing to Xulang / 参与叙廊贡献

感谢你帮助改进叙廊。Bug 报告、功能建议、文档和代码贡献都欢迎提交。维护者会根据项目的本地优先定位、质量和维护成本审核所有改动。

Thank you for improving Xulang. Bug reports, proposals, documentation, and code contributions are welcome. Every change is reviewed against the project's local-first direction, quality bar, and long-term maintenance cost.

## Before opening an issue / 提交 Issue 前

- Search existing issues and releases first. / 请先搜索已有 Issue 与 Release。
- Use the matching issue form and include reproducible steps, Android version, device model, and app version for bugs. / 使用对应表单；Bug 请提供复现步骤、Android 版本、设备型号与应用版本。
- Do not post photos, templates, logs, or recordings containing personal information. / 不要上传含个人信息的照片、模板、日志或录屏。
- Report vulnerabilities privately according to [SECURITY.md](SECURITY.md). / 安全漏洞请按安全政策私密报告。

## Development setup / 开发环境

The maintained toolchain is:

- Flutter 3.41.7 (stable)
- Dart 3.11.5
- JDK 17
- Android SDK with API 29 or newer

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub --reporter compact
flutter build apk --debug
```

Release signing belongs to maintainers. Never request or commit a keystore, `key.properties`, passwords, access tokens, or other secrets.

Release 签名只由维护者管理。禁止索取或提交 keystore、`key.properties`、密码、访问令牌或其他凭据。

## Pull requests / Pull Request 要求

1. Base work on the current `main` branch and keep each pull request focused on one change.
2. Add or update tests for changed behavior; update both Chinese and English documentation when user-facing behavior changes.
3. Run the commands above and complete the pull request checklist.
4. Allow maintainers to edit the branch so small integration fixes do not require another round trip.
5. A maintainer review and all required CI checks are required before merge.

1. 从最新 `main` 分支开始，每个 PR 聚焦一个主题。
2. 行为变化应补充测试；面向用户的变化要同步维护中英文文档。
3. 本地运行上述检查并完成 PR 清单。
4. 建议允许维护者编辑分支，以便处理小型集成调整。
5. 合并前必须通过维护者审核与所有必需 CI。

Generated Drift files are part of the repository. If a database schema change requires regeneration, include the generated output in the same pull request and explain compatibility or migration behavior.

Drift 生成文件由仓库追踪。数据库结构变化需要在同一 PR 提交生成结果，并说明兼容与迁移行为。

## Experimental iOS contributions / 实验性 iOS 贡献

Android 10+ is the only supported release target. iOS contributions are welcome as experimental work when they:

- add or retain a valid `ios/` Flutter platform directory;
- keep Android behavior and CI green;
- pass `flutter build ios --no-codesign` on the GitHub-hosted macOS runner;
- document any feature gaps, especially Android-only screen recording;
- do not add signing certificates, provisioning profiles, Apple credentials, or an IPA artifact.

当前仅正式发布 Android 10+。iOS PR 可以实验性提交，但必须通过 macOS 无签名构建、保持 Android 行为不变、说明录屏等平台差异，并且不得提交证书、描述文件、Apple 凭据或 IPA。

Acceptance of an iOS pull request does not imply that maintainers will sign or distribute an iOS build.

iOS PR 被合并不代表维护者承诺签名或发布 iOS 构建。

## Media and licensing / 素材与许可

Only submit media that you created or have the right to redistribute under terms compatible with this repository. Record the source and license when adding third-party assets. Public README captures must follow [`docs/media/README.md`](docs/media/README.md).

只能提交原创或已获得兼容再分发权利的素材；第三方素材必须记录来源与许可证。README 展示素材须遵循媒体目录说明。

By contributing, you agree that your contribution is licensed under GPL-3.0 as part of this project.

提交贡献即表示你同意该贡献作为本项目的一部分按 GPL-3.0 发布。
