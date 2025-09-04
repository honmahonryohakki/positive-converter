# フェーズ3: ポジティブ変換ロジック実装

## 目的
テキストをポジティブに変換するコアロジックとデータ層を実装する

## 作業項目

### 1. 変換エンジン実装
- [ ] `ConversionEngine.kt` 作成
- [ ] 変換ルール定義
- [ ] 単語辞書作成
- [ ] 文脈解析ロジック

### 2. データベース実装
- [ ] Room Database設定
- [ ] Entity定義
- [ ] DAO作成
- [ ] Database初期化

### 3. Repository実装
- [ ] `ConversionRepository` インターフェース
- [ ] `ConversionRepositoryImpl` 実装
- [ ] `HistoryRepository` 実装
- [ ] `SettingsRepository` 実装

### 4. UseCase実装
- [ ] `ConvertTextUseCase`
- [ ] `SaveHistoryUseCase`
- [ ] `GetHistoryUseCase`
- [ ] `DeleteHistoryUseCase`

### 5. ViewModel実装
- [ ] `MainViewModel`
- [ ] `HistoryViewModel`
- [ ] `SettingsViewModel`

## 実装コード

### ConversionEngine.kt
```kotlin
class ConversionEngine {
    
    private val conversionRules = mapOf(
        // 基本的な変換ルール
        "できない" to "チャレンジする機会がある",
        "無理" to "工夫が必要",
        "つらい" to "成長の機会",
        "疲れた" to "よく頑張った",
        "失敗" to "学びの経験",
        "問題" to "改善の余地",
        "困難" to "やりがいのある課題",
        "最悪" to "改善の余地が大きい",
        "ダメ" to "もっと良くできる",
        "嫌い" to "得意ではない",
        "面倒" to "じっくり取り組める",
        "退屈" to "新しい発見を待っている",
        "不安" to "慎重に考えている",
        "怖い" to "勇気を試される",
        "難しい" to "スキルアップのチャンス",
        "遅い" to "丁寧に進めている",
        "下手" to "練習中",
        "弱い" to "成長の余地がある",
        "悪い" to "改善可能",
        "苦手" to "これから得意になれる"
    )
    
    private val negativePatterns = listOf(
        Regex("(.+)ない") to { match: MatchResult -> 
            "${match.groupValues[1]}チャンスがある"
        },
        Regex("(.+)できなかった") to { match: MatchResult -> 
            "${match.groupValues[1]}する経験を積んだ"
        },
        Regex("(.+)しなければならない") to { match: MatchResult -> 
            "${match.groupValues[1]}する機会がある"
        }
    )
    
    fun convert(text: String): String {
        var result = text
        
        // 単語レベルの変換
        conversionRules.forEach { (negative, positive) ->
            result = result.replace(negative, positive)
        }
        
        // パターンマッチングによる変換
        negativePatterns.forEach { (pattern, replacement) ->
            result = pattern.replace(result) { matchResult ->
                replacement(matchResult)
            }
        }
        
        // 文末の変換
        result = convertSentenceEndings(result)
        
        // 感嘆符の追加（ポジティブさを強調）
        if (!result.endsWith("！") && !result.endsWith("。")) {
            result += "！"
        }
        
        return result
    }
    
    private fun convertSentenceEndings(text: String): String {
        return text
            .replace("だめだ", "大丈夫")
            .replace("終わった", "新しい始まり")
            .replace("もうダメ", "まだできる")
    }
}
```

### Database実装
```kotlin
// HistoryEntity.kt
@Entity(tableName = "conversion_history")
data class HistoryEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    @ColumnInfo(name = "original_text")
    val originalText: String,
    @ColumnInfo(name = "converted_text")
    val convertedText: String,
    @ColumnInfo(name = "timestamp")
    val timestamp: Long
)

// HistoryDao.kt
@Dao
interface HistoryDao {
    @Query("SELECT * FROM conversion_history ORDER BY timestamp DESC LIMIT 100")
    fun getAllHistory(): Flow<List<HistoryEntity>>
    
    @Insert
    suspend fun insertHistory(history: HistoryEntity)
    
    @Delete
    suspend fun deleteHistory(history: HistoryEntity)
    
    @Query("DELETE FROM conversion_history")
    suspend fun deleteAllHistory()
}

// AppDatabase.kt
@Database(
    entities = [HistoryEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun historyDao(): HistoryDao
}
```

### ViewModel実装
```kotlin
@HiltViewModel
class MainViewModel @Inject constructor(
    private val convertTextUseCase: ConvertTextUseCase,
    private val saveHistoryUseCase: SaveHistoryUseCase
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()
    
    fun onInputTextChange(text: String) {
        if (text.length <= 1000) {
            _uiState.update { 
                it.copy(
                    inputText = text,
                    charCount = text.length
                )
            }
        }
    }
    
    fun convertText() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            try {
                val converted = convertTextUseCase(_uiState.value.inputText)
                _uiState.update { 
                    it.copy(
                        convertedText = converted,
                        isLoading = false
                    )
                }
                
                // 履歴に保存
                saveHistoryUseCase(
                    originalText = _uiState.value.inputText,
                    convertedText = converted
                )
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        error = "変換中にエラーが発生しました",
                        isLoading = false
                    )
                }
            }
        }
    }
}
```

## 完了条件
- [ ] 変換ロジックが正しく動作する
- [ ] データベースに履歴が保存される
- [ ] ViewModelがUIと正しく連携する
- [ ] エラーハンドリングが実装されている