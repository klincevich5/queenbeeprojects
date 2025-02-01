# Путь к программе oCam
$ocamPath = "C:\Program Files (x86)\oCam\oCam.exe"

# Папка для сохранения записей (куда oCam изначально сохраняет)
$defaultSaveFolder = "C:\Users\user\Documents\oCam"

# Проверка, существует ли папка для записей
if (!(Test-Path -Path $defaultSaveFolder)) {
    New-Item -ItemType Directory -Path $defaultSaveFolder
}

# Проверка, запущена ли программа oCam
$ocamRunning = Get-Process -Name "oCam" -ErrorAction SilentlyContinue

if (-not $ocamRunning) {
    # Если oCam не запущен, запускаем её
    Start-Process -FilePath $ocamPath
    # Ждём, пока программа полностью загрузится
    Start-Sleep -Seconds 5
}

# Генерация уникального имени файла с форматом "Smile proof HH.mm dd.MM.yyyy"
$timestamp = (Get-Date).ToString("HH.mm dd.MM.yyyy")
$newFileName = "Smile proof $timestamp.mp4"
$destinationFilePath = Join-Path -Path $defaultSaveFolder -ChildPath $newFileName

# Начало записи (F1 для начала записи)
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("{F1}")

# Запись в течение 10 секунд
Start-Sleep -Seconds 10

# Остановка записи (F1 для остановки записи)
[System.Windows.Forms.SendKeys]::SendWait("{F1}")

# Ожидание завершения записи и проверки появления нового файла
Start-Sleep -Seconds 5
$latestFile = Get-ChildItem -Path $defaultSaveFolder -Filter "*.mp4" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($latestFile) {
    # Переименование файла в новый формат
    Rename-Item -Path $latestFile.FullName -NewName $newFileName
    Write-Output "Файл сохранён как: $destinationFilePath"

    # Задержка перед отправкой в Telegram
    Start-Sleep -Seconds 5

    # Параметры бота и групп
    $botToken = "8161154213:AAGAUAwQewPBNCT_dEQ52JdFQFMFIHHcFZE"
    $mainChatId = "-4622489328"  # Основной чат
    $backupChatId = "-1002456483885"  # Запасной чат
    
    # URL для отправки видео
    $url = "https://api.telegram.org/bot$botToken/sendVideo"
    $logUrl = "https://api.telegram.org/bot$botToken/sendMessage"

    # Загрузка сборки System.Net.Http
    Add-Type -Path "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Net.Http.dll"

    $statusMessages = @()

    # Функция отправки видео
    function Send-Video($chatId) {
        $multipartContent = New-Object System.Net.Http.MultipartFormDataContent
        $multipartContent.Add((New-Object System.Net.Http.StringContent($chatId)), "chat_id")

        $fileStream = [System.IO.File]::OpenRead($destinationFilePath)
        $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
        $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("video/mp4")
        $multipartContent.Add($fileContent, "video", [System.IO.Path]::GetFileName($destinationFilePath))

        try {
            $httpClient = New-Object System.Net.Http.HttpClient
            $response = $httpClient.PostAsync($url, $multipartContent).Result
            $responseContent = $response.Content.ReadAsStringAsync().Result

            if ($response.IsSuccessStatusCode) {
                Write-Host "Видео успешно отправлено в чат $chatId!"
                $statusMessages += "✅ Чат $chatId: Успешно"
            } else {
                Write-Host "Ошибка отправки видео в чат $chatId. Код ответа: $($response.StatusCode)"
                Write-Host "Ответ: $responseContent"
                $statusMessages += "❌ Чат $chatId: Ошибка ($($response.StatusCode))"
            }
        } catch {
            Write-Host "Ошибка при отправке в чат $chatId: $_"
            $statusMessages += "❌ Чат $chatId: Ошибка ($_)."
        } finally {
            $fileStream.Dispose()
        }
    }

    # Отправляем видео в основной чат
    Send-Video $mainChatId
    # Отправляем видео в запасной чат
    Send-Video $backupChatId

    # Отправка статуса в запасной чат
    $statusMessage = "📢 **Отчет о загрузке видео**%0A🎥 **Файл:** `$newFileName`%0A📤 **Статус отправки:**%0A" + ($statusMessages -join "%0A")
    $logParams = @{ "chat_id" = $backupChatId; "text" = $statusMessage; "parse_mode" = "Markdown" }
    Invoke-RestMethod -Uri $logUrl -Method Post -Body $logParams

} else {
    Write-Output "Ошибка: Файл записи не найден."
} 
exit
