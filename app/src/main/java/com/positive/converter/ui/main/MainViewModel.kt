package com.positive.converter.ui.main

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
// import com.positive.converter.analytics.AnalyticsManager
import com.positive.converter.domain.repository.ConversionRepository
import com.positive.converter.domain.repository.HistoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class MainUiState(
    val inputText: String = "",
    val convertedText: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val charCount: Int = 0
)

@HiltViewModel
class MainViewModel @Inject constructor(
    private val conversionRepository: ConversionRepository,
    private val historyRepository: HistoryRepository
    // private val analyticsManager: AnalyticsManager
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()
    
    fun onInputTextChange(text: String) {
        if (text.length <= 1000) {
            _uiState.update { 
                it.copy(
                    inputText = text,
                    charCount = text.length,
                    error = null
                )
            }
        }
    }
    
    fun convertText() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            try {
                val inputText = _uiState.value.inputText
                val converted = conversionRepository.convertText(inputText)
                _uiState.update { 
                    it.copy(
                        convertedText = converted,
                        isLoading = false
                    )
                }
                
                // Analytics記録 (一時的に無効化)
                // analyticsManager.logTextConverted(inputText, converted)
                
                // 履歴に保存
                if (inputText.isNotEmpty()) {
                    historyRepository.saveHistory(
                        originalText = inputText,
                        convertedText = converted
                    )
                }
            } catch (e: Exception) {
                // analyticsManager.logError("conversion_error", e.message ?: "Unknown error")
                _uiState.update { 
                    it.copy(
                        error = "変換中にエラーが発生しました",
                        isLoading = false
                    )
                }
            }
        }
    }
    
    fun clearAll() {
        _uiState.update { 
            MainUiState()
        }
    }
    
    fun copyToClipboard(context: android.content.Context) {
        val clipboard = context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
        val clip = android.content.ClipData.newPlainText("変換結果", _uiState.value.convertedText)
        clipboard.setPrimaryClip(clip)
        // analyticsManager.logCopyAction()
        // Toast表示は呼び出し元で行う
    }
    
    fun shareText(context: android.content.Context) {
        // analyticsManager.logShareAction("converted_text")
        val sendIntent = android.content.Intent().apply {
            action = android.content.Intent.ACTION_SEND
            putExtra(android.content.Intent.EXTRA_TEXT, _uiState.value.convertedText)
            type = "text/plain"
        }
        val shareIntent = android.content.Intent.createChooser(sendIntent, "共有")
        context.startActivity(shareIntent)
    }
}