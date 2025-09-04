package com.positive.converter.ui.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.positive.converter.domain.model.ConversionHistory
import com.positive.converter.domain.repository.HistoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val historyRepository: HistoryRepository
) : ViewModel() {
    
    val historyList: StateFlow<List<ConversionHistory>> = historyRepository
        .getAllHistory()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )
    
    fun deleteHistory(history: ConversionHistory) {
        viewModelScope.launch {
            historyRepository.deleteHistory(history)
        }
    }
    
    fun deleteAllHistory() {
        viewModelScope.launch {
            historyRepository.deleteAllHistory()
        }
    }
}