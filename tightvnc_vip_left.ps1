# Функция для добавления типа Win32
if (-not ([System.Management.Automation.PSTypeName]'Win32').Type) {
    Add-Type @"
        using System;
        using System.Runtime.InteropServices;

        public class Win32 {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

            public struct RECT {
                public int Left;
                public int Top;
                public int Right;
                public int Bottom;
            }

            public const uint SWP_NOZORDER = 0x0004;
            public const uint SWP_NOACTIVATE = 0x0010;
        }
"@
}

# Путь к TightVNC Viewer
$tightVncPath = "C:\Program Files\TightVNC\tvnviewer.exe"

# Данные для окон
# Данные для окон
$windowData = @(
    @{
        Title = "dui-001 - TightVNC Viewer"
        Host = "172.21.8.101"
        Password = "admin123456"
        Port = 5900
        X = -1927
        Y = 11
        Width = 653
        Height = 350
    },
    @{
        Title = "dui-002 - TightVNC Viewer"
        Host = "172.21.8.102"
        Password = "admin123456"
        Port = 5900
        X = -1927
        Y = 354
        Width = 653
        Height = 351
    },
    @{
        Title = "dui-019 - TightVNC Viewer"
        Host = "172.21.8.108"
        Password = "admin123456"
        Port = 5900
        X = -1927
        Y = 698
        Width = 653
        Height = 352
    },
    @{
        Title = "dui-004 - TightVNC Viewer"
        Host = "172.21.8.104"
        Password = "admin123456"
        Port = 5900
        X = -1288
        Y = 11
        Width = 655
        Height = 350
    }
)





# Проверка окон и запуск/перемещение
foreach ($window in $windowData) {
    $title = $window.Title
    $remoteHost = $window.Host # Переименовано из $host
    $password = $window.Password
    $port = $window.Port
    $newX = $window.X
    $newY = $window.Y
    $width = $window.Width
    $height = $window.Height

    # Получаем процессы с окнами
    $processes = Get-Process -Name "tvnviewer" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq $title }

    if ($processes) {
        # Если процесс найден, перемещаем окно
        foreach ($process in $processes) {
            $handle = $process.MainWindowHandle
            if ([Win32]::SetWindowPos($handle, [IntPtr]::Zero, $newX, $newY, $width, $height, [Win32]::SWP_NOZORDER -bor [Win32]::SWP_NOACTIVATE)) {
                Write-Host "Окно '$title' перемещено на координаты ($newX, $newY) с размерами $width x $height." -ForegroundColor Green
            } else {
                Write-Host "Не удалось переместить окно '$title'." -ForegroundColor Red
            }
        }
    } else {
        # Если процесс не найден, запускаем новое окно
        $args = @("${remoteHost}::${port}", "-password=${password}") # Используем $remoteHost
        try {
            Write-Host "Запуск нового экземпляра TightVNC Viewer для '$title'..."
            Start-Process -FilePath $tightVncPath -ArgumentList $args -NoNewWindow -ErrorAction Stop
            Start-Sleep -Seconds 2 # Даем окну время для запуска

            # Повторяем попытку поиска окна с ожиданием
            $newProcess = $null
            $retryCount = 0
            while ($retryCount -lt 3) {
                $newProcess = Get-Process -Name "tvnviewer" | Where-Object { $_.MainWindowTitle -eq $title }
                if ($newProcess) {
                    break
                }
                $retryCount++
                Start-Sleep -Seconds 3 # Ожидаем 3 секунды перед повторной попыткой
            }

            if ($newProcess) {
                foreach ($proc in $newProcess) {
                    $handle = $proc.MainWindowHandle
                    if ([Win32]::SetWindowPos($handle, [IntPtr]::Zero, $newX, $newY, $width, $height, [Win32]::SWP_NOZORDER -bor [Win32]::SWP_NOACTIVATE)) {
                        Write-Host "Новое окно '$title' перемещено на координаты ($newX, $newY) с размерами $width x $height." -ForegroundColor Green
                    } else {
                        Write-Host "Не удалось переместить новое окно '$title'." -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "Не удалось найти новое окно '$title' после попытки запуска." -ForegroundColor Red
            }
        } catch {
            Write-Host "Ошибка при запуске нового экземпляра для '$title': $_" -ForegroundColor Red
        }
    }
}
