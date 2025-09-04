# フェーズ4: テストと最適化

## 目的
アプリケーションの品質保証とパフォーマンス最適化を行う

## 作業項目

### 1. ユニットテスト実装
- [ ] ConversionEngineテスト
- [ ] ViewModelテスト
- [ ] Repositoryテスト
- [ ] UseCaseテスト

### 2. UIテスト実装
- [ ] メイン画面の操作テスト
- [ ] 履歴画面のテスト
- [ ] ナビゲーションテスト

### 3. パフォーマンス最適化
- [ ] 変換処理の高速化
- [ ] メモリ使用量の最適化
- [ ] UIレンダリングの最適化

### 4. エッジケース対応
- [ ] 空文字入力
- [ ] 最大文字数制限
- [ ] 特殊文字処理
- [ ] 絵文字対応

## テストコード

### ConversionEngineTest.kt
```kotlin
class ConversionEngineTest {
    
    private val engine = ConversionEngine()
    
    @Test
    fun `基本的なネガティブワードが変換される`() {
        val input = "今日は疲れた"
        val expected = "今日はよく頑張った！"
        val result = engine.convert(input)
        assertEquals(expected, result)
    }
    
    @Test
    fun `複数のネガティブワードが変換される`() {
        val input = "難しくて無理だし、つらい"
        val expected = "スキルアップのチャンスで工夫が必要だし、成長の機会！"
        val result = engine.convert(input)
        assertEquals(expected, result)
    }
    
    @Test
    fun `否定形が適切に変換される`() {
        val input = "できない"
        val expected = "チャレンジする機会がある！"
        val result = engine.convert(input)
        assertEquals(expected, result)
    }
    
    @Test
    fun `空文字の場合は空文字を返す`() {
        val input = ""
        val result = engine.convert(input)
        assertEquals("", result)
    }
    
    @Test
    fun `ポジティブな文章はそのまま維持される`() {
        val input = "今日は素晴らしい日だ"
        val expected = "今日は素晴らしい日だ！"
        val result = engine.convert(input)
        assertEquals(expected, result)
    }
}
```

### MainViewModelTest.kt
```kotlin
@ExperimentalCoroutinesApi
class MainViewModelTest {
    
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()
    
    private val mockConvertTextUseCase = mockk<ConvertTextUseCase>()
    private val mockSaveHistoryUseCase = mockk<SaveHistoryUseCase>()
    
    private lateinit var viewModel: MainViewModel
    
    @Before
    fun setup() {
        viewModel = MainViewModel(
            convertTextUseCase = mockConvertTextUseCase,
            saveHistoryUseCase = mockSaveHistoryUseCase
        )
    }
    
    @Test
    fun `テキスト入力時に文字数が更新される`() = runTest {
        val input = "テストテキスト"
        
        viewModel.onInputTextChange(input)
        
        val state = viewModel.uiState.value
        assertEquals(input, state.inputText)
        assertEquals(input.length, state.charCount)
    }
    
    @Test
    fun `1000文字を超える入力は受け付けない`() = runTest {
        val input = "a".repeat(1001)
        
        viewModel.onInputTextChange(input)
        
        val state = viewModel.uiState.value
        assertEquals("", state.inputText)
        assertEquals(0, state.charCount)
    }
    
    @Test
    fun `変換処理が正しく実行される`() = runTest {
        val input = "つらい"
        val converted = "成長の機会！"
        
        coEvery { mockConvertTextUseCase(input) } returns converted
        coEvery { mockSaveHistoryUseCase(any(), any()) } just Runs
        
        viewModel.onInputTextChange(input)
        viewModel.convertText()
        
        advanceUntilIdle()
        
        val state = viewModel.uiState.value
        assertEquals(converted, state.convertedText)
        assertFalse(state.isLoading)
        
        coVerify { mockSaveHistoryUseCase(input, converted) }
    }
}
```

### UIテスト
```kotlin
@RunWith(AndroidJUnit4::class)
class MainScreenTest {
    
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()
    
    @Test
    fun テキスト入力と変換ボタンクリックが動作する() {
        composeTestRule.apply {
            // テキスト入力
            onNodeWithText("ネガティブなテキストを入力")
                .performTextInput("今日は疲れた")
            
            // 変換ボタンをクリック
            onNodeWithText("ポジティブに変換")
                .performClick()
            
            // 結果が表示されることを確認
            waitForIdle()
            onNodeWithText("変換結果")
                .assertIsDisplayed()
        }
    }
    
    @Test
    fun 空のテキストでは変換ボタンが無効() {
        composeTestRule.apply {
            onNodeWithText("ポジティブに変換")
                .assertIsNotEnabled()
        }
    }
}
```

## パフォーマンス最適化

### 1. 変換処理の最適化
```kotlin
class OptimizedConversionEngine {
    // 事前コンパイルされた正規表現をキャッシュ
    private val compiledPatterns = negativePatterns.map { 
        it.first to it.second 
    }
    
    // StringBuilder使用で文字列連結を高速化
    fun convert(text: String): String {
        val builder = StringBuilder(text)
        // 処理実装
        return builder.toString()
    }
}
```

### 2. Composeの最適化
```kotlin
@Composable
fun OptimizedMainScreen() {
    // remember使用で再計算を防ぐ
    val convertedTextState = remember { mutableStateOf("") }
    
    // LazyColumnで大量データ表示
    LazyColumn {
        items(historyItems) { item ->
            HistoryItem(item)
        }
    }
}
```

## 品質チェックリスト

### 機能テスト
- [ ] すべての変換ルールが動作する
- [ ] 履歴の保存・削除が動作する
- [ ] 設定の保存が動作する
- [ ] 共有機能が動作する

### パフォーマンス
- [ ] 1000文字の変換が1秒以内
- [ ] スムーズなスクロール
- [ ] メモリリークがない

### ユーザビリティ
- [ ] 直感的な操作
- [ ] エラーメッセージが分かりやすい
- [ ] レスポンシブデザイン

## 完了条件
- [ ] テストカバレッジ80%以上
- [ ] すべてのテストがパス
- [ ] パフォーマンス要件を満たす
- [ ] クラッシュフリー率99%以上