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

画面下のボタンも長押しに対応。右のSoundボタンで即座に消音し、次回起動にも設定を保存します。
効果音は起動時に生成して再利用し、衝突処理中の波形生成を避けています。
3球排出でゲーム終了。Play againで新しいセッションが始まります。
バンパー100点、スリングショット50点、ターゲット250点、ロールオーバー150点。
シューターレーンに戻った球は再発射できます。ナッジ/ティルトは初版には含めていません。
Effectsボタンで軌跡・接触リング・浮遊得点・バンパーの発光を抑制できます。
この設定も保存され、目標ランプ・得点・残り時間は省略しません。最小ウィンドウは885×600です。
フォーカスを失うと自動的に一時停止し、押下中の操作を解放します。
ベスト記録は `user://record.cfg`（macOSのGodotアプリデータ領域）にのみ保存。
同点は新記録扱いにしません。

## 得点を伸ばすには

- **レーン**：上部の1〜3を各1回通ると、固定+500点と倍率+1（最大×5）。ランプは消えて再挑戦できます。
  同じ点灯済みレーンでも通常得点は入りますが、進捗は増えません。倍率は実際に球を失うと×1へ戻ります。
- **コンボ**：レーンとターゲットの異なるショットを3秒以内に続けると、最大5連続。
  直前と同じIDは進行・時間延長をせず、バンパー/スリングショットはコンボに影響しません。
  連続数が増えたときだけ固定 `100 × (連続数−1)` 点を追加。5連続後は異なるショットで時間を延長できますが追加ボーナスはありません。
- **Orbit Rush**：左側の3ターゲットを各1回当てると20秒間、通常接触点がさらに×2。
  発動中に再発動/延長はできず、終了時にターゲットランプが消えて再挑戦できます。
- 通常接触点は `基礎点 × レーン倍率 × Rush倍率`。レーン完成+500とコンボ加点には倍率が掛かりません。
  完成させたショットは**遷移前**の倍率で計算し、新倍率/Rushは次の接触から適用します。
- **Ball Save**：各球の最初の実発射から8秒間、1度だけ排出を救済。球数を減らさず0.8秒後に同じ球を戻します。
  レーン/ターゲット/倍率/Rushは維持し、コンボは解除。レーンへの帰還・再発射では延長も再装填もしません。
  本当に球を失うと球単位の進捗はすべて消えます。ポーズ中・再配置待ち中はルールの時間が止まります。

### デザインの参考

[Medieval Madness rules](https://www.pinball.org/rules/medievalmadness.html) の発射直後のボールセーブと点灯目標、
[Zen Mars table guide](https://www.pinballfx.com/press/table_guides/Mars%20Table%20Guide%20By%20ShoryukenToTheChin.pdf) の
3レーンによる倍率進行とミッションを、一般的なゲーム構造の参考にしました。
盤面レイアウト・画像・音声は転載せず、Orbit独自のシングルボールルールとミント/コーラルの落ち着いた表示で実装しています。

## 検証コマンド

リポジトリルートから実行。追加依存パッケージは不要です。

```sh
"$GODOT" --headless --path godot --editor --import --quit
"$GODOT" --headless --path godot --script res://tests/session_test.gd
"$GODOT" --headless --path godot --script res://tests/rules_test.gd
mkdir -p builds/physics-test-home
HOME="$PWD/builds/physics-test-home" "$GODOT" --headless --path godot --script res://tests/physics_test.gd
HOME="$PWD/builds/physics-test-home" "$GODOT" --headless --path godot --script res://tests/audio_test.gd
HOME="$PWD/builds/physics-test-home" "$GODOT" --headless --path godot --script res://tests/effects_test.gd
```

GodotのimportでGDScriptをパース・型検査します。状態テストは加点・3回排出・再開・
厳密な新記録判定・繰り返し通知の有効期限を検証。
物理テストは制御された球配置も使用します。実際のキーボードプレイの証明とは区別してください。
物理は120Hz、入力はイベントをラッチして物理tickで消費、球にCCDを有効化。
固定平面上の3D剛体に盤面下向きの力を加え、フリッパーは物理tickで回転します。
音テストはPCMの振幅・長さ・再利用、即時消音・設定保存を検証します。
ヘッドレスの再生状態検証は、実際の音声出力や音質の検証ではありません。

ルールテストは固定ボーナス・倍率・連続ID・Rush・救済/実損失と時間停止を分離して検証します。
効果テストは接触クールダウン・上限/破棄・ポーズ停止・Reduced設定とランプ保持を検証します。

### 注入状態の見た目確認（実プレイとは別）

```sh
mkdir -p builds/preview-home
HOME="$PWD/builds/preview-home" "$GODOT" --path godot --script res://tests/visual_preview.gd
```

これはレーン・ターゲットをコードで完成させ、Rush/コンボ/軌跡/加点を静止表示するプレビューです。
画面にも「CONTROLLED PREVIEW」と表示し、自然な実プレイの証拠としては扱いません。
本番.appからは `tests/*` を除外しています。状態が注入されたプレビューを通常ゲームとして配布しません。

### 描画ありのフレーム間隔測定

```sh
mkdir -p builds/perf-home
HOME="$PWD/builds/perf-home" "$GODOT" --path godot --script res://tests/performance_run.gd -- --output="$PWD/builds/performance.json"
```

5秒のウォームアップ後、30秒間の単調時計によるprocessコールバック間隔を収集し、
平均・p50/p95/p99・最大値・全生データをJSONに出力します。ウィンドウを前面に保ってください。
測定中にフォーカスを失った場合は終了コード2で無効な測定とします。
スクリプトが発射と左右操作を行う負荷試験であり、人の実プレイやGPU描画時間そのものではありません。
`--headless` は使用できません。VMの結果を物理MacやIntel Macの性能保証に流用しないでください。

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

## 今回のルール/視覚効果の検証

- macOS arm64 VMでimportと状態・ルール・物理・音・効果テストが成功。
  救済後の同一球復帰、期限切れ後の実損失、重複排出防止は制御物理/状態テストで検証。
- 新しい書き出し済み.appの実入力で、倍率上昇・COMBO 5/5・ランプ・加点リング/球跡、
  ポーズ中の時計停止・フォーカス喪失時の解放、3球終了（016600点）と再開を確認。
  Effects reducedで演出を抑制し、通常終了・再起動後も設定とBESTが保持されることを確認。
- デフォルト1180×800と小さい900×650ウィンドウ、全画面の描画を確認。HUD/操作ボタンのはみ出しなし。
- **実プレイでのBall Saveによる救済は未確認**。限定試行4球はいずれも期限後に排出しました。
  自然なOrbit Rush達成も未確認です。注入プレビューによるRush/コンボ/効果の見た目確認とは区別します。
- 新ビルドの性能測定は行っていません。音の聴覚評価とIntel実機検証も未実施です。
  音テスト終了時の既知の4 ObjectDB instances警告は残っています（assertion/終了コードは成功）。

## 以前のビルドの検証と共通制限

以下の実測値と実入力結果は品質改善コミット `7abd829` までのものです。
新しいルール/視覚効果を含むビルドの性能値ではありません。

- macOS 26.6.2 / Apple Silicon (arm64)、Apple Paravirtual Metal GPUのVMで検証。
- 上記import・状態テスト・左右の制御物理テスト・音データ/再生状態テスト・ZIP整合性・ad-hoc署名検証が成功。
- 書き出し済み.appの実入力で、発射・加点・自然な3球排出・終了・再開を確認。
  シューターレーンへの自然帰還と再発射、一時停止・フォーカス喪失時の操作解放も確認。
- フリッパーの球への打撃は制御物理テストで成功。macOS arm64での時間を区切った追試で、
  **実入力による左フリッパーの打撃も確認しました。** 右は実入力での作動を確認しましたが、
  限定追試でも明瞭な球の接触→上方離脱の証拠を得られず、実プレイでの打撃は未確認です。
  操作タイミングと自然軌道の影響を分離できず、不具合とも断定していません。球速・難易度は変更していません。
- Sound offへの切替後、通常終了・同じ.appの再起動で設定とベスト記録の保持を実入力で確認。
- 2026-10-31の上記VM上の描画ありスクリプト負荷測定：5秒ウォームアップ後、29.999秒/1795間隔。
  平均16.713ms（コールバック頻度59.835回/秒）、p50 16.678ms、p95 19.545ms、p99 20.399ms、
  最大37.899ms、33.33ms超は3回、測定中フォーカス喪失0回。Mobile/Metal、120Hz物理、Dummy audio。
  これはGPU時間や人間の実プレイFPS、改善前後の性能差を示す測定ではありません。
- Intel Macでの実行と実ハードウェアでの性能は未検証。
  VMにCoreAudio出力デバイスがなくDummy driverを使用するため、音質・消音の聴覚評価は未実施です。

## 構成

- `godot/scripts/session.gd` — UIから独立した状態・スコア
- `godot/scripts/table.gd` — 盤面、入力、物理、UI、合成音
- `godot/scripts/tone_bank.gd` — 事前生成する効果音キャッシュ
- `godot/scripts/effects.gd` — 上限付き接触効果・軌跡・浮遊点数・発光
- `godot/tests/` — 状態・制御物理・音テストと描画あり計測
- `godot/export_presets.cfg` — 秘密情報を含まないmacOSプリセット

有料/外部アセット・アカウント・オンラインサービスは使用しません。
`.godot` キャッシュと `builds` はGit管理対象外です。
