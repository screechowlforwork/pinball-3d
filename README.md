# Orbit Pinball — native macOS

Godot 4.7.2 stable / GDScript / built-in Jolt Physics による、1台の3Dピンボール。
ブラウザー・WebView・サーバーは不要です。落ち着いたミントとコーラルの配色、
ネイティブなGodot Control UI、3球制、ローカルのベスト記録、合成サウンドを備えます。
旧Webプロトタイプは別ブランチのまま維持しています。

## Macで起動

1. [公式Godot 4.7.2 stable](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) の `macos.universal.zip` をダウンロード。
2. GodotのImportから `godot/project.godot` を開き、F6ではなくF5でプロジェクトを起動。
3. または以下のコマンドを実行します（Godotの保存場所に合わせて変更）。

```sh
export GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --path godot
```

## 操作

| 操作 | キー |
|---|---|
| 左 / 右フリッパー | ← / → または Z / M |
| プランジャーを引いて発射 | Spaceを長押しして離す |
| 一時停止 / 再開 | Escape |

画面下のボタンも長押しに対応。右のSoundボタンで消音します。
3球排出でゲーム終了。Play againで新しいセッションが始まります。
バンパー100点、スリングショット50点、ターゲット250点、ロールオーバー150点。
シューターレーンに戻った球は再発射できます。ナッジ/ティルトは初版には含めていません。
フォーカスを失うと自動的に一時停止し、押下中の操作を解放します。
ベスト記録は `user://record.cfg`（macOSのGodotアプリデータ領域）にのみ保存。
同点は新記録扱いにしません。

## 検証コマンド

リポジトリルートから実行。追加依存パッケージは不要です。

```sh
"$GODOT" --headless --path godot --editor --import --quit
"$GODOT" --headless --path godot --script res://tests/session_test.gd
mkdir -p builds/physics-test-home
HOME="$PWD/builds/physics-test-home" "$GODOT" --headless --path godot --script res://tests/physics_test.gd
```

GodotのimportでGDScriptをパース・型検査します。状態テストは加点・3回排出・再開・
厳密な新記録判定・繰り返し通知の有効期限を検証。
物理テストは制御された球配置も使用します。実際のキーボードプレイの証明とは区別してください。
物理は120Hz、入力はイベントをラッチして物理tickで消費、球にCCDを有効化。
固定平面上の3D剛体に盤面下向きの力を加え、フリッパーは物理tickで回転します。

## 開発用 .app ZIP を作る

同じ公式リリースのexport templatesをGodotのManage Export Templatesからインストール。
ターミナルの場合は `templates/` 内のファイルを
`~/Library/Application Support/Godot/export_templates/4.7.2.stable/` に配置します。

```sh
mkdir -p builds
"$GODOT" --headless --path godot --export-release macOS ../builds/Orbit-Pinball-macOS.zip
ditto -x -k builds/Orbit-Pinball-macOS.zip builds/unpacked
codesign --verify --deep --strict builds/unpacked/Orbit\ Pinball.app
```

Universal 2（Apple Silicon + Intel）の開発用ad-hoc署名アプリです。
**Appleによる公証はしていません。一般公開用の署名済み配布物ではありません。**
ダウンロード後の初回起動はGatekeeperが遮断することがあります。ソースと配布元を確認し、
macOSの「システム設定 → プライバシーとセキュリティ」から対象アプリだけを許可してください。
セキュリティ機能を全体で無効化しないでください。将来の一般配布にはDeveloper ID署名と公証が必要です。
Universal出力は両CPUでの実機検証を意味しません。

## 実施済み検証と制限

- macOS 26.6.2 / Apple Silicon (arm64)、Apple Paravirtual Metal GPUのVMで検証。
- 上記import・状態テスト・制御物理テスト・ZIP整合性・ad-hoc署名検証が成功。
- 書き出し済み.appの実入力で、発射・加点・自然な3球排出・終了・再開を確認。
  シューターレーンへの自然帰還と再発射、一時停止・フォーカス喪失時の操作解放も確認。
- **フリッパーの球への打撃は制御物理テストで成功。実プレイ映像では打撃の瞬間を
  バンパー反射と区別して確証を得られていません。** フリッパー動作自体は実入力で確認。
- Intel Macでの実行、実ハードウェアでの性能、FPS/フレーム時間は未測定。
  音は合成波形を実装していますが、音質の聴覚評価は未実施です。

## 構成

- `godot/scripts/session.gd` — UIから独立した状態・スコア
- `godot/scripts/table.gd` — 盤面、入力、物理、UI、合成音
- `godot/tests/` — 決定論的な状態テストと制御物理テスト
- `godot/export_presets.cfg` — 秘密情報を含まないmacOSプリセット

有料/外部アセット・アカウント・オンラインサービスは使用しません。
`.godot` キャッシュと `builds` はGit管理対象外です。
