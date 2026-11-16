#powershell -ExecutionPolicy Bypass -File "main.ps1" *> $null
$CurrentDir = Get-Location
try {

$defaultAppName = "tg-app-x"

# Запрашиваем ввод у пользователя
$AppName = Read-Host -Prompt "Введите название приложения (по умолчанию '$defaultAppName')"

# Если ввод пустой, присваиваем значение по умолчанию
if ([string]::IsNullOrWhiteSpace($AppName)) {
    $AppName = $defaultAppName
}


$OutputDir = "D:\repos"

. ".\main.ps1" -CurrentDir $CurrentDir -AppName $AppName -OutputDir $OutputDir
} catch {
    # Перехватываем ошибку
    Write-Host "❌ Ошибка: $_" -ForegroundColor Red
    Write-Host "📝 Подробности: $($_.Exception.Message)" -ForegroundColor Yellow
} finally {
    cd $CurrentDir
}
Write-Host "FINISH TRY" -ForegroundColor Green
return


#firebase functions:secrets:set TELEGRAM_BOT_TOKEN
#8669838623:AAE8cK-jd2X7B7NMeX9TyqNISvpHKHu5Pk0
#hosts >  128.0.0.1    tr.local

