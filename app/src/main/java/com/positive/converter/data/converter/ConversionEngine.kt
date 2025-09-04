package com.positive.converter.data.converter

class ConversionEngine {
    
    private val conversionRules = mapOf(
        "できない" to "チャレンジする機会がある",
        "無理" to "工夫が必要",
        "つらい" to "成長の機会",
        "疲れた" to "よく頑張った",
        "疲れる" to "充実している",
        "失敗" to "学びの経験",
        "問題" to "改善の余地",
        "困難" to "やりがいのある課題",
        "最悪" to "改善の余地が大きい",
        "ダメ" to "もっと良くできる",
        "嫌い" to "得意ではない",
        "嫌" to "好みではない",
        "面倒" to "じっくり取り組める",
        "退屈" to "新しい発見を待っている",
        "不安" to "慎重に考えている",
        "怖い" to "勇気を試される",
        "難しい" to "スキルアップのチャンス",
        "遅い" to "丁寧に進めている",
        "下手" to "練習中",
        "弱い" to "成長の余地がある",
        "悪い" to "改善可能",
        "苦手" to "これから得意になれる",
        "めんどくさい" to "じっくり取り組む価値がある",
        "やばい" to "注目に値する",
        "きつい" to "鍛えられている",
        "しんどい" to "頑張っている証拠",
        "つまらない" to "新しい楽しみ方を見つけられる",
        "うざい" to "気になる存在",
        "むかつく" to "感情を動かされる",
        "イライラ" to "エネルギーが満ちている",
        "ストレス" to "成長への刺激",
        "憂鬱" to "じっくり考える時間",
        "心配" to "大切に思っている",
        "緊張" to "集中している",
        "恥ずかしい" to "謙虚な気持ち",
        "寂しい" to "人とのつながりを大切にしている",
        "悲しい" to "感受性が豊か",
        "辛い" to "乗り越える力を持っている",
        "苦しい" to "限界に挑戦している",
        "痛い" to "体が教えてくれている",
        "怒り" to "情熱的",
        "諦め" to "新しい道を探す機会",
        "挫折" to "再スタートのチャンス",
        "絶望" to "希望を見つける旅の始まり"
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
        },
        Regex("(.+)のせいで") to { match: MatchResult -> 
            "${match.groupValues[1]}のおかげで学べた"
        }
    )
    
    fun convert(text: String): String {
        if (text.isEmpty()) return ""
        
        var result = text
        
        // 単語レベルの変換（長い単語から優先的に変換）
        conversionRules.entries
            .sortedByDescending { it.key.length }
            .forEach { (negative, positive) ->
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
        if (result.isNotEmpty() && !result.endsWith("！") && !result.endsWith("。") && !result.endsWith("?")) {
            result += "！"
        }
        
        return result
    }
    
    private fun convertSentenceEndings(text: String): String {
        return text
            .replace("だめだ", "大丈夫")
            .replace("ダメだ", "大丈夫")
            .replace("終わった", "新しい始まり")
            .replace("もうダメ", "まだできる")
            .replace("もう無理", "もう少し頑張れる")
            .replace("死にたい", "生きる価値がある")
            .replace("消えたい", "存在する意味がある")
    }
}