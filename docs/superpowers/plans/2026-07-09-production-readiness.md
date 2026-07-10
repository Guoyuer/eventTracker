# 生产级化实施计划 (Production Readiness Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## 执行状态（交接快照，2026-07-09）

**Task 1–3 已完成**（提交 `b80f539`、`7d9069a`、`49d0e24`+`36a5f3d`+`ca9c69f`），**从 Task 4 继续**。每个已完成 Task 都经过独立 spec+quality 审查。执行中的发现，后续 Task 必须遵守：

- **当前基线已变**：`flutter test` 是 **112 个测试**（下文 Global Constraints 写的 108 是计划时点的旧值）。analyze 依旧必须 `No issues found!`（CI 用 `--fatal-infos`）。
- **`drift` 被钉在 2.34.0**（Task 3 Step 0 走了预案 B；原因见 pubspec.yaml 内注释）。不要解开，除非 drift_dev 修复了 schema 工具与 drift 2.34.1+ 的不兼容。
- **SQL 字符串里禁止使用指数字面量**（如 `1e308`、`1.79e308`）：drift_dev 2.34.0 的 sqlparser 用整数幂解析指数，e308 溢出归零，会把约束静默损坏（Task 3 审查实锤）。用普通十进制写法。
- **不要把 Dart 常量内插进 `customConstraints`**：drift_dev 会静默丢弃整个 CHECK（Task 3 修复时实锤）。`tables.dart` 的 CHECK 保持字符串字面量，与 domain 常量 `maxRecordValue` 的一致性由测试锁住。
- **记录值上限现在是 1e15**（`lib/domain/` 的 `maxRecordValue`），Dart 校验与 SQL CHECK 两层对齐,勿单独改任何一层。
- 改 schema 前先读 `app_database.dart` 中 `schemaVersion` 上方的注释（dump/generate 流程,Task 3 建立）。
- 审查遗留的 Minor 项（不阻塞,留给最终全分支审查统一处理）记录在 `.superpowers/sdd/progress.md`。

**Goal:** 把这个已经具备干净分层的 Flutter 活动记录 app，推到可以安全发版、并且能低成本迭代新功能的状态。

**Architecture:** 现有分层（`domain` / `application` / `state` / `persistence` / UI）是健康的，且由 `test/architecture_dependencies_test.dart` 的 import 边界测试强制。本计划**不重构分层**。它补的是分层之外的生产要素：CI 闸门、数据持久性与迁移安全、错误可观测性、类型不变量的最后一块缺口、i18n，以及把 lint 从「临时放宽」拉回严格。

**Tech Stack:** Flutter 3.44.5 / Dart SDK ^3.12.0、Riverpod 3.x、Drift 2.34 (+ drift_sqflite 移动端 / sqflite_common_ffi 桌面与测试)、fl_chart、flutter_lints 6。

## Global Constraints

- Dart SDK 约束 `^3.12.0`，Flutter stable 3.44.5。不要升级这两个。
- 每个 Task 结束时 `flutter analyze` 必须 **`No issues found!`**，`flutter test` 必须全绿。当前基线：analyze 干净，**112 个测试全部通过**（21 个测试文件）。
- 不得放宽 `test/architecture_dependencies_test.dart` 的规则。`lib/domain/`、`lib/application/`、`lib/analytics/` 不允许 import Flutter、Riverpod 或 `lib/persistence/`。
- 不得引入新的 denormalized 汇总字段。`Activity` 的一切数值必须继续由 `ActivityRecordHistory.evaluate` 从 `Records` 推导（`lib/persistence/activity_snapshot_store.dart:58`）。
- 修改 `lib/persistence/database/tables.dart` 或 `sql.drift` 之后，必须跑 `dart run build_runner build` 重新生成 `app_database.g.dart`，并把生成物一起提交。
- 每个 Task 独立提交。提交信息用英文祈使句（跟现有 git history 一致，如 `Enforce activity unit integrity`）。

## 已经做对的，不要动

先说清楚，避免下游 agent「顺手重构」：

- **单一事实来源**：`Events` 表上没有 `sum_time` / `sum_val` 缓存，所有汇总从 `Records` 推导。
- **「同一活动至多一条进行中记录」由数据库强制**：部分唯一索引 `records_one_active_per_event ON records(event_id) WHERE end_time IS NULL`，且 `sql.drift:9` 与迁移路径 `lib/persistence/database/app_database.dart:97,218` 都建了它。不要改成应用层检查。
- **`Activity` 的 sealed 层级**（`lib/domain/activity_models.dart:1-70`）让「进行中的计时活动必有 `startedAt`」在类型上成立。
- **记录形状的 CHECK 约束**（`lib/persistence/database/tables.dart:44-52`）。
- **架构边界测试**。

---

## 缺口清单（本计划要解决的，按证据排序）

| # | 问题 | 证据 | Task |
|---|---|---|---|
| 1 | 没有 CI，任何回归都靠人肉发现 | 仓库无 `.github/workflows/` | 1 |
| 2 | `PRAGMA synchronous = OFF`，掉电/系统崩溃会丢已提交事务 | `app_database.dart:20` | 2 |
| 3 | schemaVersion 已到 6，手写迁移，但没有 schema 快照与 drift 迁移校验器 | 无 `drift_schemas/` 目录 | 3 |
| 4 | 无全局错误边界；`recordActivity` 无 try/catch，`StateError` 会变成未捕获异步异常 | `lib/EventsList/eventsList.dart:113`；全仓库无 `runZonedGuarded` / `FlutterError.onError` | 4 |
| 5 | `catch (_)` 吞掉真实异常，然后向用户猜原因（"可能是因为项目名重复"） | `activity_editor_controller.dart:31`、`unit_management_controller.dart:25,44` | 4 |
| 6 | `ActivityRecord` 没有 sealed，靠可空字段 + `requiredStartTime` 运行时抛错，与 `Activity` 不对称 | `lib/domain/activity_models.dart:72-95` | 5 |
| 7 | 80 处硬编码中文，且 `localizationsDelegates` 只注册了 `GlobalMaterialLocalizations` | `lib/main.dart:24,77` | 6 |
| 8 | 25 条 lint 规则被关闭，`analysis_options.yaml` 自己写着 "tighten incrementally" | `analysis_options.yaml` | 7 |
| 9 | 顶层可变全局 `var chartTitleStyle` / `gradientColors`，游离于 provider 图外 | `lib/common/const.dart:3,13` | 8 |

**这 8 个 Task 之间的依赖**：Task 1 应当最先做（它是让后面所有改动「粘住」的棘轮）。Task 4 依赖 Task 1（CI 才能看到新测试）。其余 Task 相互独立，可乱序，也可并行分派。

---

### Task 1: CI 闸门

**Files:**
- Create: `.github/workflows/ci.yaml`

**Interfaces:**
- Consumes: 无。
- Produces: 一个在每次 push / PR 上运行 `flutter analyze` 与 `flutter test` 的 workflow。后续所有 Task 依赖它作为回归网。

**为什么第一个做：** 这个仓库的质量提升要靠棘轮（ratchet）而不是靠自律。没有 CI，Task 7 把 lint 收紧之后，下一个 PR 就能重新引入违规。

- [x] **Step 1: 写 workflow**

创建 `.github/workflows/ci.yaml`：

```yaml
name: CI

on:
  push:
    branches: [master]
  pull_request:

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.5'
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Verify generated code is up to date
        run: |
          dart run build_runner build --delete-conflicting-outputs
          git diff --exit-code -- '*.g.dart'

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Test
        run: flutter test
```

三个非显然的选择，解释一下：

- `dart format --set-exit-if-changed`：仓库当前已经是 `dart format` 后的状态，所以这一步现在就能过。它防止后续 diff 里混入格式噪音。
- **`git diff --exit-code -- '*.g.dart'`**：这一步捕获「改了 `tables.dart` 却忘了跑 build_runner」。这是 drift 项目最常见的一类脏提交。
- `--fatal-infos`：Task 7 会打开一批 lint，其中不少默认是 info 级别。没有这个 flag，CI 会对它们视而不见。

- [x] **Step 2: 本地验证每一条命令都能过**

依次运行，四条都必须成功：

```bash
dart format --output=none --set-exit-if-changed .
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- '*.g.dart'
flutter analyze --fatal-infos
flutter test
```

Expected: 前三条静默退出 0；`flutter test` 输出 `All tests passed!`。

如果 `flutter analyze --fatal-infos` 报错（`--fatal-infos` 比裸 `flutter analyze` 严），**不要在这个 Task 里放宽 lint**。修掉它们，或者把对应规则加进 `analysis_options.yaml` 的关闭列表并在 Task 7 处理。记录你关掉了哪几条。

- [x] **Step 3: 提交**

```bash
git add .github/workflows/ci.yaml
git commit -m "Add CI gate for format, codegen, analyze, and tests"
```

---

### Task 2: 修复数据持久性 (`synchronous = OFF`)

**Files:**
- Modify: `lib/persistence/database/app_database.dart:17-21`
- Test: `test/app_database_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`（`lib/persistence/database/app_database.dart:9`）。
- Produces: 无新 API。行为变化：`beforeOpen` 设置 `journal_mode = WAL` 与 `synchronous = NORMAL`。

**问题：** `app_database.dart:20` 现在是：

```dart
await customStatement('PRAGMA synchronous = OFF');
```

`synchronous = OFF` 意味着 SQLite 提交事务时**不等待数据真正落盘**。进程崩溃还能活（OS 缓冲还在），但设备掉电、内核 panic、或 iOS/Android 强杀时机不巧，用户已经「记录成功」的活动会消失，甚至数据库文件损坏。对一个记账/习惯追踪类 app，这是最不能接受的失败模式——用户不会注意到丢了一条，只会慢慢发现数据不对。

`journal_mode = WAL` + `synchronous = NORMAL` 是移动端的标准组合：WAL 下 `NORMAL` 只在 checkpoint 时 fsync，不在每次 commit 时 fsync，所以性能接近 `OFF`，但**不会因为掉电而损坏数据库**（最坏情况是丢掉最后几个未 checkpoint 的事务，而不是整库损坏）。

- [x] **Step 1: 写失败的测试**

在 `test/app_database_test.dart` 末尾追加（放进已有的顶层 `main()` 里的最外层 `group` 之外，或直接作为独立 `test(...)`——跟随文件现有结构）：

```dart
  test('database opens with durable journal and synchronous settings', () async {
    final db = AppDatabase(testExecutor());

    final journalMode = await db
        .customSelect('PRAGMA journal_mode')
        .getSingle();
    final synchronous = await db
        .customSelect('PRAGMA synchronous')
        .getSingle();

    expect(
      (journalMode.data.values.first as String).toLowerCase(),
      'wal',
    );
    // 0 = OFF, 1 = NORMAL, 2 = FULL
    expect(synchronous.data.values.first, 1);

    await db.close();
  });
```

`testExecutor()` 是这个测试文件里已有的 helper——**先读 `test/app_database_test.dart` 的开头**，用它实际的 in-memory executor 构造方式（不要臆造名字）。如果它用的是内存数据库，注意 SQLite 内存库**不支持 WAL**，`PRAGMA journal_mode=WAL` 会静默返回 `memory`。这种情况下改成建一个临时文件数据库：

```dart
final file = File(p.join(Directory.systemTemp.createTempSync().path, 'wal.sqlite'));
final db = AppDatabase(NativeDatabase(file));
```

并在测试末尾 `await db.close(); file.parent.deleteSync(recursive: true);`。

- [x] **Step 2: 跑测试确认它失败**

Run: `flutter test test/app_database_test.dart -r compact`
Expected: FAIL，`synchronous` 实际是 `0`（OFF），`journal_mode` 是 `delete`。

- [x] **Step 3: 改实现**

`lib/persistence/database/app_database.dart`，把 `beforeOpen` 改成：

```dart
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = NORMAL');
    },
```

**顺序重要**：`journal_mode` 必须在 `synchronous` 之前设置，否则 `NORMAL` 的语义是 rollback-journal 下的语义（每次 commit 仍 fsync），性能会掉。

- [x] **Step 4: 跑测试确认通过**

Run: `flutter test test/app_database_test.dart -r compact`
Expected: PASS

然后跑全量：`flutter test`
Expected: `All tests passed!`

- [x] **Step 5: 提交**

```bash
git add lib/persistence/database/app_database.dart test/app_database_test.dart
git commit -m "Use WAL journaling with durable synchronous mode"
```

---

### Task 3: Drift schema 快照与迁移校验器

**Files:**
- Create: `drift_schemas/drift_schema_v6.json`（由命令生成，不要手写）
- Create: `test/generated_migrations/`（由命令生成）
- Create: `test/schema_verifier_test.dart`
- Modify: `pubspec.yaml`（dev_dependencies 增加 `sqlite3`）
- Modify: `.github/workflows/ci.yaml`（把 schema 目录纳入 codegen 校验）

**Interfaces:**
- Consumes: `AppDatabase`、`schemaVersion == 6`。
- Produces: `drift_schemas/` 下的版本化 schema 快照；`test/generated_migrations/schema.dart` 导出 `GeneratedHelper`，供 `SchemaVerifier` 使用。

**问题：** 这个 app 的迁移是手写 SQL（`app_database.dart:41-221`），已经走到 v6，而且做了 `DROP TABLE steps`、删除 `event_id = -1` 的哨兵行、以及对畸形数据 `throw StateError` 这类**不可逆**操作。目前没有任何东西验证「v5 的库升到 v6 之后，结构跟全新安装的 v6 完全一致」。手写迁移最经典的事故就是：新装用户走 `onCreate` 拿到正确 schema，老用户走 `onUpgrade` 少了一个索引或一个 CHECK，然后在几个月后以一种无法调试的方式炸掉。

`database_migration_test.dart`（284 行）测的是**数据**在迁移中的行为，这很好，但它不比对**结构**。drift 官方的 `SchemaVerifier` 正是干这个的。

**一个必须诚实交代的限制：** `drift_dev schema dump` 只能导出**当前代码**的 schema。v1–v5 的快照现在已经无法凭空生成（那些版本的表定义部分来自 drift 之前的 sqflite 时代）。所以本 Task 建立的是 **v6 作为基线**，从此保证 v6 → v7 → … 的每一次迁移都被结构校验。历史迁移继续由现有的 `database_migration_test.dart` 用数据层面的测试覆盖。这是能做到的最好结果，不要假装能补回 v1–v5。

> ### ⚠️ 已验证的前置阻塞：drift_dev 的 schema 工具当前跑不起来
>
> 我在写这份计划时实际执行了 `dart run drift_dev schema --help`，它**编译失败**：
>
> ```
> Failed to build drift_dev:drift_dev:
> drift_dev-2.34.0/lib/src/services/schema/verifier_common.dart:340:13: Error:
>   The non-abstract class '_GenerateFromScratchDrift3' is missing implementations
>   for these members: - GeneratedDatabase.schema
> drift_dev-2.34.0/lib/src/services/schema/verifier_common.dart:45:28: Error:
>   The getter 'allSchemaEntities' isn't defined for the type 'GeneratedDatabase'.
> ```
>
> 这是 `drift_dev 2.34.0` 与 `drift 2.34.1` 的上游不兼容（`drift3_preview` 改了 `GeneratedDatabase` 的接口，drift_dev 的 verifier 还没跟上）。注意：**`build_runner` 生成 `.g.dart` 是正常的**，坏掉的只是 `drift_dev` 的 `schema` 可执行入口，也就是本 Task 需要的那个。
>
> `flutter pub outdated` 显示 `drift_dev` 最新是 **2.34.2+1**，但当前**可解析**版本被卡在 2.34.0。最可能的原因是 `pubspec.yaml` 里那条直接的 `analyzer: ^12.1.0` dev 依赖——它是 `test/architecture_dependencies_test.dart` 真正需要的（那个测试用 analyzer 解析 import），所以**不能简单删掉**。
>
> **Step 0 必须先解决这个，否则 Step 2 起全部无法执行。**

- [x] **Step 0: 解开 drift_dev 的版本锁（这是本 Task 的真正工作）**

按顺序尝试，命中即停：

**尝试 A** —— 放宽 analyzer，让 pub 解析出 `drift_dev 2.34.2+1`：

```bash
# 把 pubspec.yaml 的 dev_dependencies 里
#   analyzer: ^12.1.0
# 改为
#   analyzer: '>=12.1.0 <14.0.0'
flutter pub upgrade drift_dev
dart run drift_dev schema --help
```

Expected（成功时）：打印 `dump` / `generate` / `steps` 子命令的用法，无编译错误。

然后 `flutter test test/architecture_dependencies_test.dart` 必须仍然通过——如果 analyzer 大版本变动破坏了它的 AST API 用法，回退到尝试 B。

**尝试 B** —— 反向锁定 `drift` 到与 `drift_dev 2.34.0` 匹配的版本：

```bash
# pubspec.yaml: drift: ^2.34.1  →  drift: 2.34.0
flutter pub get
dart run drift_dev schema --help
```

**尝试 C** —— 若 A、B 都失败：**停下来向人汇报**，不要绕过。不要手写 schema JSON，不要跳过本 Task 直接做 Task 4。没有迁移校验器就改 schema，正是这个 Task 要防的事故。在报告里附上 `dart run drift_dev schema --help` 的完整输出和 `flutter pub outdated` 的结果。

无论走哪条路，把结论记进 commit message，并在 `pubspec.yaml` 相应约束上加一行注释说明为什么被钉住。

Expected（Step 0 完成）：`dart run drift_dev schema --help` 正常输出；`flutter analyze --fatal-infos && flutter test` 全绿。

- [x] **Step 1: 加 dev_dependency**

`pubspec.yaml` 的 `dev_dependencies` 里加一行（`sqlite3` 是 `SchemaVerifier` 在测试里建库需要的）：

```yaml
dev_dependencies:
  analyzer: ^12.1.0
  flutter_test:
    sdk: flutter
  build_runner: ^2.15.1
  drift_dev: ^2.34.0
  flutter_lints: ^6.0.0
  sqlite3: ^2.4.0
```

Run: `flutter pub get`

- [x] **Step 2: 导出 v6 schema 快照**

```bash
dart run drift_dev schema dump lib/persistence/database/app_database.dart drift_schemas/
```

Expected: 生成 `drift_schemas/drift_schema_v6.json`。

打开它确认里面出现了 `records_one_active_per_event`。如果没有，说明 `include: {'sql.drift'}` 的索引没被 dump 到，**停下来报告**，不要继续。

- [x] **Step 3: 生成校验器代码**

```bash
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

Expected: 生成 `test/generated_migrations/schema.dart` 和 `test/generated_migrations/schema_v6.dart`。

- [x] **Step 4: 写校验测试**

创建 `test/schema_verifier_test.dart`：

```dart
import 'package:drift_dev/api/migrations.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('a freshly created database matches the v6 schema snapshot', () async {
    final connection = await verifier.startAt(6);
    final db = AppDatabase(connection);

    await verifier.migrateAndValidate(db, 6);

    await db.close();
  });
}
```

这个测试现在只锁住「v6 就是 v6」。真正的价值在下一次改 schema 时兑现：见 Step 6 的交接说明。

- [x] **Step 5: 跑测试**

Run: `flutter test test/schema_verifier_test.dart -r compact`
Expected: PASS

然后全量 `flutter test`，Expected: `All tests passed!`

- [x] **Step 6: 把流程写进 CI 和文档**

在 `.github/workflows/ci.yaml` 的 "Verify generated code is up to date" 步骤里，把 schema 生成也纳入：

```yaml
      - name: Verify generated code is up to date
        run: |
          dart run build_runner build --delete-conflicting-outputs
          dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
          git diff --exit-code -- '*.g.dart' test/generated_migrations/
```

并在 `lib/persistence/database/app_database.dart` 的 `schemaVersion` 上方加一条注释——这是**唯一**该加的注释，因为它表达的是代码本身无法表达的流程约束：

```dart
  /// 改动此值前必须先运行:
  ///   dart run drift_dev schema dump lib/persistence/database/app_database.dart drift_schemas/
  ///   dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
  /// 然后在 test/schema_verifier_test.dart 中为新版本加一条 migrateAndValidate 用例。
  @override
  int get schemaVersion => 6;
```

- [x] **Step 7: 提交**

```bash
git add pubspec.yaml pubspec.lock drift_schemas/ test/generated_migrations/ \
        test/schema_verifier_test.dart .github/workflows/ci.yaml \
        lib/persistence/database/app_database.dart
git commit -m "Snapshot schema v6 and verify migrations structurally"
```

---

### Task 4: 错误边界与类型化失败

**Files:**
- Create: `lib/domain/activity_failure.dart`
- Create: `lib/bootstrap/error_boundary.dart`
- Modify: `lib/main.dart:15-18`
- Modify: `lib/persistence/drift_activity_repository.dart:51-78`
- Modify: `lib/persistence/drift_unit_repository.dart`（接口在 `lib/domain/unit_repository.dart`：`addUnit(String) → Future<int>`、`deleteUnit(String) → Future<void>`）
- Modify: `lib/application/activity_editor_controller.dart:23-35`
- Modify: `lib/application/unit_management_controller.dart:20-49`
- Modify: `lib/application/activity_list_controller.dart:36-50`
- Test: `test/activity_failure_test.dart`（新建）、`test/activity_repository_test.dart`、`test/activity_list_controller_test.dart`

**Interfaces:**
- Consumes: `ActivityWriter.createActivity`、`RecordLifecycle`、`UnitRepository`。
- Produces:
  - `sealed class ActivityFailure implements Exception`，子类 `DuplicateActivityName(String name)`、`DuplicateUnitName(String name)`、`UnitInUse(String name)`、`ActivityBusy(int activityId)`。
  - `Future<void> runGuarded(Future<void> Function() body, {required void Function(Object, StackTrace) onError})`（`lib/bootstrap/error_boundary.dart`）。
  - `ActivityListController.recordActivity` 的签名不变，但内部把 `ActivityFailure` 转成 `_notify(...)`。

**与 Task 6 的关系（先读）：** 本 Task 会在 controller 里写中文字面量（如 `'该项目正在计时中'`）。这是**刻意的临时状态**。`application` 层被架构测试禁止 import Flutter，因此它拿不到 `AppLocalizations`。Task 6 会把这些字面量改成由 UI 层注入的消息对象。如果你在做 Task 6 之后才做本 Task，直接采用注入方案，跳过字面量。

**这个 Task 解决两个纠缠在一起的问题。**

**问题 A：静默崩溃。** `lib/EventsList/eventsList.dart:113` 里 `_submitRecording` 直接 `return controller.recordActivity(...)`，而 `recordActivity` 内部没有任何 try/catch。如果 `startTimedRecord` 抛 `StateError('Timed Activity 3 is already active')`——比如用户双击、或者数据库里已有一条活动记录——这个异常会成为未捕获的异步异常。Debug 下红屏，Release 下**什么都不发生**：用户点了按钮，计时没开始，没有任何提示。全仓库搜不到 `FlutterError.onError` 或 `runZonedGuarded`，所以也没有任何地方能记录它。

**问题 B：`catch (_)` 在猜。** `activity_editor_controller.dart:31`：

```dart
    } catch (_) {
      _notify('添加失败，可能是因为项目名重复！');
      return false;
    }
```

「可能是」这三个字诚实地暴露了：代码不知道自己为什么失败。磁盘满了、unit 不存在（`drift_activity_repository.dart:65` 抛 `StateError('Unit ... does not exist')`）、名字重复——用户都会看到「可能是因为项目名重复」。`unit_management_controller.dart:44` 的 `_notify('删除失败')` 同理，它把「该单位正被某个活动引用」（外键 `onDelete: KeyAction.restrict`）这个完全可解释的原因，压成了一句没有信息量的话。

**设计决定：** 在 domain 定义 sealed 的失败类型，在 persistence 把「底层错误」翻译成它们，controller 只 catch `ActivityFailure` 并展示确定的消息，**其他一切异常继续上抛**给错误边界。

为什么不靠捕获 drift/sqlite 的唯一约束异常来识别「重名」？因为这个 app 移动端走 `drift_sqflite`（抛 sqflite 的 `DatabaseException`），桌面和测试走 `sqflite_common_ffi`，异常类型不一致，靠 `e.toString().contains('UNIQUE constraint failed')` 是脆的。改为**在事务内显式先查后插**：唯一索引仍然是最终的正确性保证（并发下 insert 会失败），显式查询只是为了给出一个确定的、可测试的失败类型。

- [ ] **Step 1: 写失败类型（无测试，纯声明）**

创建 `lib/domain/activity_failure.dart`：

```dart
/// 用户可以理解、UI 应当解释的失败。
/// 不属于此层级的异常一律视为 bug，交给错误边界。
sealed class ActivityFailure implements Exception {
  const ActivityFailure();
}

final class DuplicateActivityName extends ActivityFailure {
  const DuplicateActivityName(this.name);

  final String name;
}

final class DuplicateUnitName extends ActivityFailure {
  const DuplicateUnitName(this.name);

  final String name;
}

final class UnitInUse extends ActivityFailure {
  const UnitInUse(this.name);

  final String name;
}

final class ActivityBusy extends ActivityFailure {
  const ActivityBusy(this.activityId);

  final int activityId;
}
```

- [ ] **Step 2: 写失败的 repository 测试**

在 `test/activity_repository_test.dart` 里追加（沿用该文件已有的 `setUp` / repository 构造方式，先读它）：

```dart
    test('createActivity throws DuplicateActivityName on a name clash', () async {
      await repository.createActivity(name: '跑步', careTime: true);

      expect(
        () => repository.createActivity(name: ' 跑步 ', careTime: true),
        throwsA(isA<DuplicateActivityName>()),
      );
    });
```

注意 `' 跑步 '` 带空格：`normalizeRequiredName` 会 trim，`COLLATE NOCASE UNIQUE` 会判定重复。这条测试同时锁住了归一化与冲突检测。

记得在文件头 import：
```dart
import 'package:event_tracker/domain/activity_failure.dart';
```

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/activity_repository_test.dart -r compact`
Expected: FAIL —— 抛出的是 sqflite/sqlite 的约束异常，不是 `DuplicateActivityName`。

- [ ] **Step 4: 在 repository 里翻译失败**

`lib/persistence/drift_activity_repository.dart`，头部加 import：

```dart
import '../domain/activity_failure.dart';
```

把 `createActivity` 整体替换为（注意：包进事务，并且顺手修掉 `description` 没有归一化这个既有不一致）：

```dart
  @override
  Future<int> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  }) {
    final normalizedName = normalizeRequiredName(name, field: 'activityName');
    final normalizedUnit = normalizeOptionalName(unit, field: 'unitName');
    final normalizedDescription = normalizeOptionalName(
      description,
      field: 'description',
    );

    return _db.transaction(() async {
      final existing = await (_db.select(_db.events)
            ..where((row) => row.name.equals(normalizedName)))
          .getSingleOrNull();
      if (existing != null) {
        throw DuplicateActivityName(normalizedName);
      }

      Unit? selectedUnit;
      if (normalizedUnit != null) {
        selectedUnit = await (_db.select(
          _db.units,
        )..where((row) => row.name.equals(normalizedUnit))).getSingleOrNull();
        if (selectedUnit == null) {
          throw StateError('Unit $normalizedUnit does not exist');
        }
      }

      return _db
          .into(_db.events)
          .insert(
            EventsCompanion(
              name: Value(normalizedName),
              careTime: Value(careTime),
              unitId: Value(selectedUnit?.id),
              description: Value(normalizedDescription),
            ),
          );
    });
  }
```

`name.equals(...)` 依赖列上的 `COLLATE NOCASE`（`tables.dart:16`），因此大小写不同的重名也会命中。

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/activity_repository_test.dart -r compact`
Expected: PASS

- [ ] **Step 6: 提交这一半**

```bash
git add lib/domain/activity_failure.dart lib/persistence/drift_activity_repository.dart \
        test/activity_repository_test.dart
git commit -m "Introduce typed activity failures for name conflicts"
```

- [ ] **Step 7: 对 unit repository 做同样的事**

先读 `lib/persistence/` 下的 unit repository 实现与 `lib/domain/unit_repository.dart`。在 `addUnit` 里，事务内先查后插，重名抛 `DuplicateUnitName(name)`。在 `deleteUnit` 里，先查是否有 `events.unit_id` 引用它，有则抛 `UnitInUse(name)`（外键 `KeyAction.restrict` 仍是最终保证）。

对应地在 `test/unit_repository_test.dart` 里，把已有的两条测试——`repository keeps database uniqueness for unit names` 和 `repository refuses to delete a Unit used by an Activity`——的断言从泛泛的 `throwsA(anything)` 收紧为 `throwsA(isA<DuplicateUnitName>())` 与 `throwsA(isA<UnitInUse>())`。**先读这两条测试当前断言的是什么**；如果它们已经断言了具体类型，按实际情况调整。

Run: `flutter test test/unit_repository_test.dart -r compact` → PASS

```bash
git add lib/persistence lib/domain/unit_repository.dart test/unit_repository_test.dart
git commit -m "Introduce typed unit failures for conflicts and restricted deletes"
```

- [ ] **Step 8: 让 controller 停止猜测**

`lib/application/activity_editor_controller.dart`，把 catch 块改为：

```dart
    } on DuplicateActivityName catch (failure) {
      _notify('已存在名为「${failure.name}」的项目');
      return false;
    }
```

（删掉 `catch (_)`。其它异常上抛。）

`lib/application/unit_management_controller.dart`：

```dart
  Future<bool> addUnit(String name) async {
    try {
      await _repository.addUnit(name);
      _refresh();
      return true;
    } on DuplicateUnitName catch (failure) {
      _notify('已存在名为「${failure.name}」的单位');
      return false;
    }
  }

  Future<bool> deleteUnit(
    String name, {
    required UnitDeleteConfirmation confirmDelete,
  }) async {
    final confirmed = await confirmDelete();
    if (!confirmed) {
      return false;
    }

    try {
      await _repository.deleteUnit(name);
      _refresh();
      return true;
    } on UnitInUse catch (failure) {
      _notify('「${failure.name}」正被某个项目使用，无法删除');
      _refresh();
      return false;
    }
  }
```

两个文件都要 `import '../domain/activity_failure.dart';`。

- [ ] **Step 9: 让 recordActivity 捕获竞态**

`lib/persistence/record_lifecycle_store.dart:45`，把

```dart
        throw StateError('Timed Activity $activityId is already active');
```

改为

```dart
        throw ActivityBusy(activityId);
```

并加 import。然后在 `lib/application/activity_list_controller.dart` 的 `recordActivity` 外面包一层：

```dart
  Future<void> recordActivity(
    Activity activity,
    DateTime recordedAt, {
    required ActivityValuePrompt requestValue,
  }) async {
    try {
      switch (activity) {
        case PlainActivity():
          await _addPlainRecord(activity, recordedAt, requestValue);
        case ActiveTimedActivity():
          await _stopTimedRecord(activity, recordedAt, requestValue);
        case InactiveTimedActivity():
          await _recordLifecycle.startTimedRecord(activity.id, recordedAt);
          _refresh();
      }
    } on ActivityFailure {
      _notify('该项目正在计时中');
      _refresh();
    }
  }
```

`_refresh()` 在失败分支里很关键：`ActivityBusy` 说明 UI 拿到的 `Activity` 快照已经过期，必须重新拉取，否则用户会一直看到「未在计时」的按钮。

- [ ] **Step 10: 为这个竞态写测试**

`test/activity_list_controller_test.dart` 里追加。该文件已经有 fake `RecordLifecycle` 的模式——**先读它**，复用同一个 fake，给它加一个「让 `startTimedRecord` 抛 `ActivityBusy` 」的开关：

```dart
    test('recordActivity surfaces a busy activity and refreshes', () async {
      lifecycle.startTimedRecordFailure = const ActivityBusy(7);
      final controller = ActivityListController(
        recordLifecycle: lifecycle,
        refresh: () => refreshCount++,
        notify: notifications.add,
      );

      await controller.recordActivity(
        const InactiveTimedActivity(
          id: 7,
          name: '跑步',
          totalDuration: Duration.zero,
          totalValue: 0,
        ),
        DateTime(2026, 7, 9),
        requestValue: (_) async => null,
      );

      expect(notifications, ['该项目正在计时中']);
      expect(refreshCount, 1);
    });
```

Run: `flutter test test/activity_list_controller_test.dart -r compact` → 先 FAIL（fake 还没有那个字段 / controller 还没 catch），实现后 PASS。

- [ ] **Step 11: 装上全局错误边界**

创建 `lib/bootstrap/error_boundary.dart`：

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

/// 在一个捕获所有未处理异常的 zone 里运行 [body]。
/// 同步的 framework 异常经由 [FlutterError.onError] 汇入同一个 [onError]。
Future<void> runGuarded(
  Future<void> Function() body, {
  required void Function(Object error, StackTrace stackTrace) onError,
}) {
  final completer = Completer<void>();

  runZonedGuarded(
    () async {
      FlutterError.onError = (details) {
        onError(details.exception, details.stack ?? StackTrace.current);
      };
      await body();
      if (!completer.isCompleted) completer.complete();
    },
    (error, stackTrace) {
      onError(error, stackTrace);
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    },
  );

  return completer.future;
}
```

`lib/main.dart` 改为：

```dart
void main() {
  runGuarded(
    () async {
      await bootstrapApp();
      runApp(ProviderScope(child: EventTracker()));
    },
    onError: (error, stackTrace) {
      // 目前只保证异常不再静默消失。接入 Crashlytics / Sentry 时，
      // 把上报调用放在这里，这是进程内唯一的汇聚点。
      FlutterError.presentError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    },
  );
}
```

加 import `import 'bootstrap/error_boundary.dart';`，并删掉 `main` 原来的 `async`。

这个 Task **不接入**崩溃上报服务——那需要你决定用哪家、以及隐私政策。它做的是把「异常无处可去」变成「异常有且只有一个出口」。

- [ ] **Step 12: 全量验证并提交**

```bash
flutter analyze --fatal-infos && flutter test
```
Expected: `No issues found!` 且 `All tests passed!`

```bash
git add lib/ test/
git commit -m "Route unhandled errors through a single boundary"
```

---

### Task 5: 把 `ActivityRecord` 也 seal 掉

**Files:**
- Modify: `lib/domain/activity_models.dart:72-95`
- Modify: `lib/persistence/drift_activity_repository.dart`（`getActivityRecords` 的映射）
- Modify: `lib/analytics/activity_detail_analytics.dart`（消费 `ActivityRecord` 的地方）
- Test: `test/activity_detail_analytics_test.dart`、`test/activity_repository_test.dart`

**Interfaces:**
- Consumes: `ActivityReader.getActivityRecords(int) → Future<List<ActivityRecord>>`。
- Produces: `sealed class ActivityRecord`，子类 `PlainRecord`（`endedAt` 非空、无 `startedAt`）、`CompletedTimedRecord`（`startedAt` + `endedAt` 均非空）、`ActiveTimedRecord`（只有 `startedAt`，无 `value`）。所有子类保留 `id`、`activityId`、`value`。

**为什么：** `Activity` 已经 sealed，illegal state 构造不出来。但同一个 domain 文件下面的 `ActivityRecord`（`activity_models.dart:72-95`）还停留在旧范式：

```dart
  DateTime get requiredStartTime {
    return startTime ?? (throw StateError('Timed Record $id has no start time'));
  }
```

数据库已经用 CHECK 约束保证了记录只可能是三种形状之一（`tables.dart:44-52`），`ActivityRecordHistory.evaluate` 也在运行时重新验证了一遍。唯独类型系统不知道。结果就是每个消费者都得处理理论上不可能的 null，或者调用一个会抛异常的 getter。这是这个仓库「领域建模」维度距离满分的主要原因。

顺带修掉一处分层泄漏：字段叫 `eventId`（`activity_models.dart:75`），这是持久层的表名渗进了 domain。改叫 `activityId`。

- [ ] **Step 1: 写失败的测试**

创建 `test/activity_record_shape_test.dart`：

```dart
import 'package:event_tracker/domain/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an active timed record exposes a start and no value', () {
    const record = ActiveTimedRecord(
      id: 1,
      activityId: 2,
      startedAt: null,
    );

    expect(record, isA<ActivityRecord>());
  });
}
```

（这条先写成**编译不过**的形态是刻意的：`startedAt: null` 必须被类型系统拒绝。Step 2 你会看到编译错误，然后把它改成正确形态。）

- [ ] **Step 2: 确认它编译失败**

Run: `flutter test test/activity_record_shape_test.dart -r compact`
Expected: 编译错误 —— `ActiveTimedRecord` 未定义。

- [ ] **Step 3: 实现 sealed 层级**

`lib/domain/activity_models.dart`，把 `class ActivityRecord {...}`（第 72–95 行）整体替换为：

```dart
sealed class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.activityId,
    this.value,
  });

  final int id;
  final int activityId;
  final double? value;
}

/// 无计时活动的一次发生。只有结束时刻。
final class PlainRecord extends ActivityRecord {
  const PlainRecord({
    required super.id,
    required super.activityId,
    required this.endedAt,
    super.value,
  });

  final DateTime endedAt;
}

/// 已结束的计时记录。`endedAt >= startedAt` 由数据库 CHECK 保证。
final class CompletedTimedRecord extends ActivityRecord {
  const CompletedTimedRecord({
    required super.id,
    required super.activityId,
    required this.startedAt,
    required this.endedAt,
    super.value,
  });

  final DateTime startedAt;
  final DateTime endedAt;

  Duration get duration => endedAt.difference(startedAt);
}

/// 正在计时的记录。数据库 CHECK 保证它没有 value。
final class ActiveTimedRecord extends ActivityRecord {
  const ActiveTimedRecord({
    required super.id,
    required super.activityId,
    required this.startedAt,
  }) : super(value: null);

  final DateTime startedAt;
}
```

`ActiveTimedRecord` 没有 `endedAt`，`PlainRecord` 没有 `startedAt`——这正是重点：这两个字段不是「碰巧为 null」，而是在该形态下**不存在**。

同时把 `test/activity_record_shape_test.dart`（Step 1 里那个故意编译不过的版本）改成有意义的断言：

```dart
void main() {
  test('a completed timed record derives its duration', () {
    final record = CompletedTimedRecord(
      id: 1,
      activityId: 2,
      startedAt: DateTime(2026, 7, 9, 10),
      endedAt: DateTime(2026, 7, 9, 10, 30),
    );

    expect(record.duration, const Duration(minutes: 30));
  });

  test('an active timed record cannot carry a value', () {
    final record = ActiveTimedRecord(
      id: 1,
      activityId: 2,
      startedAt: DateTime(2026, 7, 9, 10),
    );

    expect(record.value, isNull);
  });
}
```

- [ ] **Step 4: 更新 repository 映射**

在 `lib/persistence/drift_activity_repository.dart` 的 `getActivityRecords` 里，把每行 `Record` 翻译成正确的子类。**先读现有实现**，然后照这个形状改：

```dart
  ActivityRecord _toDomain(Record row) {
    final startedAt = row.startTime;
    final endedAt = row.endTime;

    if (startedAt == null) {
      if (endedAt == null) {
        throw StateError('Record ${row.id} has neither a start nor an end');
      }
      return PlainRecord(
        id: row.id,
        activityId: row.eventId,
        endedAt: endedAt,
        value: row.value,
      );
    }
    if (endedAt == null) {
      return ActiveTimedRecord(
        id: row.id,
        activityId: row.eventId,
        startedAt: startedAt,
      );
    }
    return CompletedTimedRecord(
      id: row.id,
      activityId: row.eventId,
      startedAt: startedAt,
      endedAt: endedAt,
      value: row.value,
    );
  }
```

这个 `throw StateError` 是唯一残留的运行时检查，位置正确：它守在**持久层与 domain 的边界**上，把数据库 CHECK 已经保证过的东西再确认一次。domain 内部从此不需要任何 null 检查。

- [ ] **Step 5: 更新消费者**

搜索所有用到 `requiredStartTime` / `requiredValue` / `.eventId` / `.startTime` / `.endTime` 的地方：

```bash
grep -rn "requiredStartTime\|requiredValue\|\.eventId" lib/analytics lib/application lib/EventsDetails
```

把它们改成对 sealed 类型的 `switch`。例如 `lib/analytics/activity_detail_analytics.dart` 里按记录时刻分桶的地方，用：

```dart
    for (final record in records) {
      final occurredAt = switch (record) {
        PlainRecord(:final endedAt) => endedAt,
        CompletedTimedRecord(:final endedAt) => endedAt,
        ActiveTimedRecord() => null,
      };
      if (occurredAt == null) continue;
      // ...
    }
```

穷尽的 `switch` 不需要 `default`——这正是 sealed 的收益：以后加一种记录形态，编译器会指着每一个 switch 让你处理。

- [ ] **Step 6: 全量验证**

Run: `flutter analyze --fatal-infos && flutter test`
Expected: `No issues found!` 且全绿。

如果 `ActivityRecord` 上的 `requiredStartTime` / `requiredValue` 已经没有任何调用者，删掉它们（此时它们应该已经不在新的 sealed 定义里了）。

- [ ] **Step 7: 提交**

```bash
git add lib/ test/
git commit -m "Make illegal record shapes unrepresentable"
```

---

### Task 6: 国际化 (i18n)

**Files:**
- Create: `l10n.yaml`
- Create: `lib/l10n/app_zh.arb`
- Create: `lib/l10n/app_en.arb`
- Modify: `pubspec.yaml`（`flutter: generate: true`）
- Modify: `lib/main.dart:23-31`
- Modify: 所有含硬编码中文字符串的文件（当前 80 处）

**Interfaces:**
- Consumes: `flutter_localizations`（已在依赖里）。
- Produces: `AppLocalizations.of(context)!`，由 `flutter gen-l10n` 生成到 `.dart_tool/flutter_gen/`。

**问题：** `lib/main.dart:24` 只注册了 `GlobalMaterialLocalizations.delegate`，缺 `GlobalWidgetsLocalizations` 与 `GlobalCupertinoLocalizations`——这意味着 Material 组件被本地化了，但 widgets 层（比如文本方向、`DefaultTextStyle`）和 Cupertino 组件没有。同时 `supportedLocales` 声明支持 `en`，但界面上 80 处字符串是硬编码中文，`main.dart:77` 甚至用字符串拼接组标题：`"活动记录本 - " + bottomLabels[selectedIdx]`。英文用户会看到一个中文 app。

这是**功能迭代成本**问题而不只是洁癖问题：只要字符串还散落在 widget 里，任何新页面都会继续散落，且没有任何机制阻止。

- [ ] **Step 1: 打开 l10n 生成**

创建 `l10n.yaml`：

```yaml
arb-dir: lib/l10n
template-arb-file: app_zh.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

`pubspec.yaml` 的 `flutter:` 段加一行：

```yaml
flutter:
  uses-material-design: true
  generate: true
```

- [ ] **Step 2: 建立 arb 文件**

`lib/l10n/app_zh.arb`（模板；先放 Task 4 里新增的和 `main.dart` 的，剩下的逐文件迁移）：

```json
{
  "@@locale": "zh",
  "appTitle": "活动记录本",
  "appTitleWithSection": "活动记录本 - {section}",
  "@appTitleWithSection": {
    "placeholders": { "section": { "type": "String" } }
  },
  "tabActivities": "项目",
  "tabStatistics": "统计",
  "tabSettings": "选项",
  "emptyData": "暂无数据",
  "retry": "重试",
  "cancel": "取消",
  "confirm": "确认",
  "invalidValue": "请输入大于 0 的有限数值",
  "timingCancelled": "已取消本次计时",
  "activityBusy": "该项目正在计时中",
  "duplicateActivityName": "已存在名为「{name}」的项目",
  "@duplicateActivityName": {
    "placeholders": { "name": { "type": "String" } }
  },
  "duplicateUnitName": "已存在名为「{name}」的单位",
  "@duplicateUnitName": {
    "placeholders": { "name": { "type": "String" } }
  },
  "unitInUse": "「{name}」正被某个项目使用，无法删除",
  "@unitInUse": {
    "placeholders": { "name": { "type": "String" } }
  }
}
```

`lib/l10n/app_en.arb`：同样的 key，英文值，且**不需要** `@` 元数据（模板文件里已声明）：

```json
{
  "@@locale": "en",
  "appTitle": "Activity Tracker",
  "appTitleWithSection": "Activity Tracker - {section}",
  "tabActivities": "Activities",
  "tabStatistics": "Statistics",
  "tabSettings": "Settings",
  "emptyData": "No data yet",
  "retry": "Retry",
  "cancel": "Cancel",
  "confirm": "Confirm",
  "invalidValue": "Enter a finite number greater than 0",
  "timingCancelled": "Timing cancelled",
  "activityBusy": "This activity is already being timed",
  "duplicateActivityName": "An activity named \"{name}\" already exists",
  "duplicateUnitName": "A unit named \"{name}\" already exists",
  "unitInUse": "\"{name}\" is used by an activity and cannot be deleted"
}
```

Run: `flutter gen-l10n`
Expected: 无报错。

- [ ] **Step 3: 修 main.dart 的 delegates 与标题**

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ...

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // ...
```

`MainPage` 里，把 `bottomLabels` 这个实例字段删掉（它是硬编码中文的来源），改为在 `build` 里从 context 取：

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sections = [l10n.tabActivities, l10n.tabStatistics, l10n.tabSettings];
    final selectedIdx = ref.watch(selectedIndexProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitleWithSection(sections[selectedIdx])),
      ),
      // ... items 用 sections[0..2]
```

注意 `title:` 从 `MaterialApp` 移到了 `onGenerateTitle:`——`title` 是静态字符串，拿不到 localized context。

- [ ] **Step 4: 逐文件迁移剩余字符串**

按这个顺序（从叶子到根，每个文件一次提交，保持 diff 可读）：

1. `lib/common/async_state.dart:31,46`（`暂无数据`、`重试`）— 需要把 `AsyncStateView` 的 `errorMessage` / `emptyMessage` 保持为 `String` 参数（调用方传 localized 值），只把内部默认值 `'暂无数据'` 换成必填参数。
2. `lib/EventsList/events_list_helpers.dart`（`取消`、`确认`、`请输入大于 0 的有限数值`）
3. `lib/application/*_controller.dart` —— **注意**：controller 在 `application` 层，架构测试禁止它 import Flutter。所以 controller **不能**调用 `AppLocalizations`。保持现状：controller 通过 `_notify(String)` 回调接收已经本地化的文案，由 UI 层在构造 controller 时注入。也就是说 Task 4 里我写在 controller 里的中文字面量，要变成构造参数或由调用方传入的 message provider。

   这是一个真实的设计约束，不要为了图快去 import Flutter 破坏架构测试。最简做法：给 controller 加一个 `ActivityFailureMessages` 值对象（纯 Dart，放 `lib/application/`），由 UI 层从 `AppLocalizations` 填充后注入。

4. `lib/EventsDetails/`、`lib/Statistics/`、`lib/UnitManager/`、`lib/eventEditor.dart`、`lib/settingPage.dart`

每迁完一个文件跑一次 `flutter analyze --fatal-infos && flutter test`。

- [ ] **Step 5: 加一条防回归的测试**

创建 `test/no_hardcoded_strings_test.dart`。它跟 `architecture_dependencies_test.dart` 是同一类东西——**用测试把约定变成强制**：

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UI source contains no hardcoded CJK string literals', () {
    final cjk = RegExp(r'''(['"])[^'"]*[一-鿿][^'"]*\1''');
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('l10n')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (cjk.hasMatch(line)) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(offenders, isEmpty, reason: '把这些字符串移进 lib/l10n/*.arb');
  });
}
```

注释里的中文被跳过了（`startsWith('//')`），这是有意的——注释不面向用户。

Run: `flutter test test/no_hardcoded_strings_test.dart -r compact`
Expected: PASS（如果还有遗漏，它会把文件:行号全列出来，继续迁移直到清空）。

- [ ] **Step 6: 提交**

```bash
git add l10n.yaml lib/ pubspec.yaml test/no_hardcoded_strings_test.dart
git commit -m "Localize user-facing strings and enforce it with a test"
```

---

### Task 7: 收紧 lint

**Files:**
- Modify: `analysis_options.yaml`
- Modify: 被规则命中的各文件
- Rename: `lib/eventEditor.dart`、`lib/settingPage.dart`、`lib/common/commonWidget.dart`、`lib/heatmap_calendar/heatMap.dart`、`lib/heatmap_calendar/heatMapBuildingBlocks.dart`、`lib/EventsList/eventsList.dart`、`lib/EventsDetails/eventDetails.dart`、`lib/UnitManager/unitsManagerPage.dart`

**Interfaces:**
- Consumes: 无。
- Produces: 更严格的 `analysis_options.yaml`；文件重命名后所有 import 路径更新。

**背景：** `analysis_options.yaml` 里关掉了 25 条规则，注释诚实地写着 "This repo is being lifted from a prototype baseline. Keep correctness warnings visible now, then tighten style rules incrementally." 现在是兑现「incrementally」的时候。这个 Task 分成三批，**每批一个提交**，因为一次全开会产生几百个 diff，没法 review。

**先决条件：** Task 1 的 CI 必须已经在跑，否则收紧的规则会被下一个 PR 悄悄侵蚀。

- [ ] **Step 1: 第一批 —— 纯自动修复，零风险**

从关闭列表里删掉这些行：

```
    prefer_const_constructors: false
    prefer_const_constructors_in_immutables: false
    prefer_const_literals_to_create_immutables: false
    prefer_collection_literals: false
    prefer_conditional_assignment: false
    prefer_interpolation_to_compose_strings: false
    unnecessary_new: false
    unnecessary_this: false
    prefer_final_fields: false
    sized_box_for_whitespace: false
    avoid_unnecessary_containers: false
    sort_child_properties_last: false
    annotate_overrides: false
```

然后：

```bash
dart fix --apply
dart format .
flutter analyze --fatal-infos
flutter test
```

Expected: `dart fix` 自动改掉绝大多数；analyze 干净；测试全绿。

`prefer_const_constructors` 会顺手解决一批 widget 重建开销——这不是纯风格，`const` widget 在 rebuild 时会被跳过。

```bash
git add -A && git commit -m "Enable auto-fixable lint rules"
```

- [ ] **Step 2: 第二批 —— 需要人工判断的正确性规则**

删掉：

```
    use_build_context_synchronously: false
    library_private_types_in_public_api: false
    use_key_in_widget_constructors: false
    use_super_parameters: false
    curly_braces_in_flow_control_structures: false
    no_leading_underscores_for_local_identifiers: false
    prefer_typing_uninitialized_variables: false
    avoid_function_literals_in_foreach_calls: false
```

`use_build_context_synchronously` 是这批里唯一真正抓 bug 的：它会命中所有「`await` 之后继续用 `BuildContext`」的地方。这个 app 有好几处——`lib/EventsList/eventsList.dart:138` 的 `onTap: () async { ... Navigator.of(context) ... }`、`lib/EventsList/events_list_helpers.dart` 的对话框。修法是在 `await` 前抓住需要的对象，或者 `await` 后检查 `if (!context.mounted) return;`。

**逐个修，不要 `// ignore:`。** 每修一个跑一次 `flutter analyze --fatal-infos`。

```bash
dart fix --apply && dart format . && flutter analyze --fatal-infos && flutter test
git add -A && git commit -m "Enable correctness lints and fix context-after-await usages"
```

- [ ] **Step 3: 第三批 —— 文件重命名**

最后删掉 `file_names: false`。

用 `git mv` 保留历史：

```bash
git mv lib/eventEditor.dart lib/activity_editor_page.dart
git mv lib/settingPage.dart lib/settings_page.dart
git mv lib/common/commonWidget.dart lib/common/common_widgets.dart
git mv lib/heatmap_calendar/heatMap.dart lib/heatmap_calendar/heat_map.dart
git mv lib/heatmap_calendar/heatMapBuildingBlocks.dart lib/heatmap_calendar/heat_map_building_blocks.dart
git mv lib/EventsList/eventsList.dart lib/EventsList/activity_list_page.dart
git mv lib/EventsDetails/eventDetails.dart lib/EventsDetails/activity_detail_page.dart
git mv lib/UnitManager/unitsManagerPage.dart lib/UnitManager/units_manager_page.dart
```

**目录名先不动**（`EventsList/`、`EventsDetails/`、`UnitManager/`）。`file_names` lint 只管文件名。目录重命名会和 `architecture_dependencies_test.dart` 里的路径断言冲突，属于独立的一次改动，留到以后。

然后修所有 import。`flutter analyze` 会把每一个断掉的 import 指出来。

```bash
flutter analyze --fatal-infos && flutter test
git add -A && git commit -m "Rename source files to snake_case"
```

- [ ] **Step 4: 确认关闭列表已清空**

此时 `analysis_options.yaml` 的 `rules:` 段应该是空的（或整个 `linter:` 段可以删掉），只剩：

```yaml
include: package:flutter_lints/flutter.yaml
```

Run: `flutter analyze --fatal-infos`
Expected: `No issues found!`

```bash
git add analysis_options.yaml && git commit -m "Remove lint suppressions"
```

---

### Task 8: 消除可变全局状态

**Files:**
- Modify: `lib/common/const.dart`
- Modify: `lib/Statistics/statistics_charts.dart`、`lib/EventsDetails/activity_detail_charts.dart`（消费 `chartTitleStyle` / `gradientColors` 的地方）
- Test: `test/no_mutable_globals_test.dart`（新建）

**Interfaces:**
- Consumes: `ThemeData`。
- Produces: `AppChartTheme extends ThemeExtension<AppChartTheme>`，携带 `titleStyle` 与 `heatmapGradient`；通过 `Theme.of(context).extension<AppChartTheme>()!` 读取。

**问题：** `lib/common/const.dart:3` 与 `:13`：

```dart
var chartTitleStyle = TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);
LinearGradient gradientColors = LinearGradient(colors: [...]);
```

两个都是**顶层可变变量**。任何代码都可以给它们赋值，赋值不会触发任何 rebuild，测试之间也会互相污染（一个测试改了它，下一个测试看到脏值）。它们游离在 Riverpod 的 provider 图之外，是这个仓库「状态管理」维度唯一的实质性扣分项。

同一个文件里的 `heatmapColorMap` 已经是 `const Map` —— 说明作者知道该怎么做，只是这两个漏了。

- [ ] **Step 1: 写会失败的守卫测试**

创建 `test/no_mutable_globals_test.dart`：

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib declares no mutable top-level variables', () {
    // 顶层声明 = 行首无缩进。匹配 `var x =` 或 `Type x =`，
    // 但放过 `const`、`final`、函数、类、typedef 等。
    final mutableTopLevel = RegExp(
      r'''^(?!\s)(?!const |final |class |sealed |abstract |enum |typedef |void |mixin |extension |import |export |part )'''
      r'''[\w<>,\s?]+\s+\w+\s*=''',
    );
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (mutableTopLevel.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty, reason: '顶层可变状态；改用 const 或 ThemeExtension');
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/no_mutable_globals_test.dart -r compact`
Expected: FAIL，列出 `lib/common/const.dart:3` 与 `lib/common/const.dart:13`。

如果它还报出别的文件，**先看一眼**——可能是真的漏网之鱼，也可能是正则误伤。误伤就收紧正则，别放宽断言。

- [ ] **Step 3: 建 ThemeExtension**

创建 `lib/common/app_chart_theme.dart`：

```dart
import 'package:flutter/material.dart';

@immutable
class AppChartTheme extends ThemeExtension<AppChartTheme> {
  const AppChartTheme({
    required this.titleStyle,
    required this.heatmapGradient,
  });

  static const AppChartTheme fallback = AppChartTheme(
    titleStyle: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
    heatmapGradient: LinearGradient(
      colors: [
        Color.fromARGB(255, 235, 237, 240),
        Color.fromARGB(255, 155, 233, 168),
        Color.fromARGB(255, 64, 196, 99),
        Color.fromARGB(255, 48, 161, 78),
        Color.fromARGB(255, 33, 110, 57),
      ],
    ),
  );

  final TextStyle titleStyle;
  final LinearGradient heatmapGradient;

  @override
  AppChartTheme copyWith({
    TextStyle? titleStyle,
    LinearGradient? heatmapGradient,
  }) {
    return AppChartTheme(
      titleStyle: titleStyle ?? this.titleStyle,
      heatmapGradient: heatmapGradient ?? this.heatmapGradient,
    );
  }

  @override
  AppChartTheme lerp(AppChartTheme? other, double t) {
    if (other == null) return this;
    return AppChartTheme(
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t)!,
      heatmapGradient:
          LinearGradient.lerp(heatmapGradient, other.heatmapGradient, t)!,
    );
  }
}
```

`lib/main.dart` 的 `ThemeData` 里注册：

```dart
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        extensions: const [AppChartTheme.fallback],
      ),
```

- [ ] **Step 4: 替换消费点**

```bash
grep -rn "chartTitleStyle\|gradientColors" lib
```

每一处改成：

```dart
    final chartTheme = Theme.of(context).extension<AppChartTheme>()!;
    // ... chartTheme.titleStyle / chartTheme.heatmapGradient
```

然后从 `lib/common/const.dart` 删掉 `chartTitleStyle` 与 `gradientColors`，只留 `const Map<int, Color> heatmapColorMap`。

- [ ] **Step 5: 验证**

Run: `flutter test test/no_mutable_globals_test.dart -r compact` → PASS
Run: `flutter analyze --fatal-infos && flutter test` → 全绿

- [ ] **Step 6: 提交**

```bash
git add lib/ test/
git commit -m "Move chart styling into a theme extension"
```

---

## 完成之后

跑完 8 个 Task，按本仓库最初的评分口径，预期变化：

| 维度 | 现在 | 预期 | 主要归因 |
|---|---|---|---|
| 架构 | 9 | 9 | 已经靠 import 边界测试强制，本计划不动它 |
| 领域建模与类型安全 | 8 | 9 | Task 5 消灭最后一处「可空 + 运行时抛错」 |
| 状态管理 | 7 | 8 | Task 8 清除可变全局 |
| 代码质量 | 6 | 8 | Task 6 + 7：字符串外提、lint 归零、文件名统一 |
| 测试 | 9 | 9 | 已经很强；Task 3/6/8 各加一条强制型测试 |
| 可维护性 | 6 | 8 | Task 1 的 CI 棘轮 + Task 3 的迁移安全网 |

**剩下没做、需要你自己决策的：**

1. **崩溃上报**：Task 4 建好了唯一出口（`main.dart` 的 `onError`），但没接任何服务。接 Sentry 还是 Firebase Crashlytics 涉及隐私政策与账号，我不替你选。
2. **`Events` 表改名为 `Activities`**：domain 说 Activity，schema 说 Events，`drift_activity_repository.dart` 全程做翻译。改名需要一次 schema 迁移（v7），有 Task 3 的校验器之后做这件事才是安全的。收益是消灭这层翻译；成本是一次数据迁移。**建议做，但排在 Task 3 之后。**
3. **验证规则的三处重复**（`input_validation.dart:30` 的 Dart 校验、`tables.dart:44-52` 的 SQL CHECK、`app_database.dart:112-123` 的迁移守卫）。两个独立评审都把它列为头号弱点。我的判断是：**不要试图把三者合并成一处**——它们服务于三个不同的时刻（应用写入前、数据库写入时、旧数据升级时），SQL CHECK 无法调用 Dart。正确的做法是加一条**一致性测试**：构造一批边界值（`0`、`-1`、`double.infinity`、`NaN`、`1e308`），断言「Dart 校验拒绝」当且仅当「直接 INSERT 触发 CHECK 失败」。这样重复依然存在，但**漂移会被立刻发现**。这条测试值得写，但它不是本计划的一部分，因为它需要先想清楚边界值集合。
4. **widget 测试只有 4 个文件**。domain 和 persistence 覆盖得很好，UI 层基本没测。等 Task 6 的 l10n 落地后再补，否则测试里会写死中文字符串。
