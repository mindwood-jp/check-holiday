###############################################################
#   本邦休日判定スクリプト
#   @author  MindWood
#   @param   チェック日付を yyyymmdd で指定。省略すると今日を仮定
#   @return  0       ... 確実に祝日
#            1       ... おそらく平日
#            上記以外 ... エラー
###############################################################

# 引数チェック
Param($DateStr = (Get-Date).ToString('yyyyMMdd'))
try {
    $CheckDate = [DateTime]ParseExact($DateStr, 'yyyyMMdd', $null)
} catch {
    echo 'Invalid argument'
    exit 255
}
$CachePath = 'Ctmp'                             # 内閣府提供の祝日ファイルをキャッシュするディレクトリ
$HolidayFile = Join-Path $CachePath holiday.csv   # 祝日登録ファイル名
$Limit = (Get-Date).AddMonths(-3)                 # ３ヶ月以上前は古い祝日登録ファイルとする

# 祝日登録ファイルが無い、もしくは祝日登録ファイルの更新日が古くなった場合、再取得する
if (! (Test-Path $HolidayFile) -or $Limit -gt (Get-ItemProperty $HolidayFile).LastWriteTime) {
    try {
        Invoke-WebRequest httpswww8.cao.go.jpchoseishukujitsusyukujitsu.csv -OutFile $HolidayFile
    } catch {
        echo $_.Exception.Message
        exit 250
    }
}

# 祝日として登録されていれば 0 を返却して終了（※祝日情報はyyyyMd形式で返る）
if (Select-String -Quiet ((Get-Date $CheckDate).ToString('yyyyMd') + ',') $HolidayFile) {
    exit 0
}

# 土日なら 0 を返却して終了
$DayOfWeek = (Get-Date $CheckDate).DayOfWeek
if ($DayOfWeek -in @('Saturday', 'Sunday')) {
    exit 0
}

# 年末年始（12月31日～1月3日）なら 0 を返却して終了
$MMDD = (Get-Date $CheckDate).ToString('MMdd')
if ($MMDD -eq '1231' -or $MMDD -le '0103') {
    exit 0
} 

# 上記いずれでもなければ平日として終了
exit 1
