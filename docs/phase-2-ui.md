# フェーズ2: UI実装

## 目的
Jetpack Composeを使用してユーザーインターフェースを実装する

## 作業項目

### 1. テーマ設定
- [ ] Material3 テーマ設定
- [ ] カラーパレット定義
- [ ] タイポグラフィ設定
- [ ] ダークモード対応

### 2. メイン画面実装
- [ ] `MainScreen.kt` 作成
- [ ] テキスト入力フィールド
- [ ] 変換ボタン
- [ ] 結果表示エリア
- [ ] 文字数カウンター

### 3. 履歴画面実装
- [ ] `HistoryScreen.kt` 作成
- [ ] 履歴リスト表示
- [ ] 削除機能UI
- [ ] 空状態表示

### 4. 設定画面実装
- [ ] `SettingsScreen.kt` 作成
- [ ] テーマ切り替えスイッチ
- [ ] フォントサイズ設定
- [ ] アプリ情報表示

### 5. ナビゲーション実装
- [ ] `Navigation.kt` 作成
- [ ] BottomNavigationBar
- [ ] 画面遷移設定

## 実装コード例

### MainScreen.kt
```kotlin
@Composable
fun MainScreen(
    viewModel: MainViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // 入力エリア
        OutlinedTextField(
            value = uiState.inputText,
            onValueChange = viewModel::onInputTextChange,
            label = { Text("ネガティブなテキストを入力") },
            modifier = Modifier.fillMaxWidth(),
            maxLines = 5
        )
        
        // 文字数表示
        Text(
            text = "${uiState.charCount}/1000",
            style = MaterialTheme.typography.bodySmall
        )
        
        // 変換ボタン
        Button(
            onClick = viewModel::convertText,
            modifier = Modifier.fillMaxWidth(),
            enabled = uiState.inputText.isNotEmpty()
        ) {
            Text("ポジティブに変換")
        }
        
        // 結果表示
        if (uiState.convertedText.isNotEmpty()) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "変換結果",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = uiState.convertedText,
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Row {
                        IconButton(onClick = viewModel::copyToClipboard) {
                            Icon(Icons.Default.ContentCopy, "コピー")
                        }
                        IconButton(onClick = viewModel::share) {
                            Icon(Icons.Default.Share, "共有")
                        }
                    }
                }
            }
        }
    }
}
```

### Theme.kt
```kotlin
@Composable
fun PositiveConverterTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        darkTheme -> darkColorScheme(
            primary = Color(0xFF4CAF50),
            secondary = Color(0xFF8BC34A)
        )
        else -> lightColorScheme(
            primary = Color(0xFF4CAF50),
            secondary = Color(0xFF8BC34A)
        )
    }
    
    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
```

## UIコンポーネント一覧

### 共通コンポーネント
1. **ConversionCard**: 変換結果表示カード
2. **HistoryItem**: 履歴リストアイテム
3. **EmptyState**: 空状態表示
4. **LoadingIndicator**: ローディング表示

## 完了条件
- [ ] すべての画面が表示できる
- [ ] ナビゲーションが動作する
- [ ] ダークモードが切り替わる
- [ ] レスポンシブデザインが適用されている