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
        Title = "dui-003 - TightVNC Viewer"
        Host = "172.21.8.103"
        Password = "admin123456"
        Port = 5900
        X = 1913
        Y = 9
        Width = 335
        Height = 521
    },
    @{
        Title = "dui-011 - TightVNC Viewer"
        Host = "172.21.8.111"
        Password = "admin123456"
        Port = 5900
        X = 2234
        Y = 9
        Width = 331
        Height = 521
    },
    @{
        Title = "dui-013 - TightVNC Viewer"
        Host = "172.21.8.113"
        Password = "admin123456"
        Port = 5900
        X = 2551
        Y = 9
        Width = 336
        Height = 521
    },
    @{
        Title = "dui-010 - TightVNC Viewer"
        Host = "172.21.8.110"
        Password = "admin123456"
        Port = 5900
        X = 2873
        Y = 9
        Width = 336
        Height = 521
    },
    @{
        Title = "dui-015 - TightVNC Viewer"
        Host = "172.21.8.115"
        Password = "admin123456"
        Port = 5900
        X = 3195
        Y = 9
        Width = 349
        Height = 521
    },
    @{
        Title = "dui-012 - TightVNC Viewer"
        Host = "172.21.8.112"
        Password = "admin123456"
        Port = 5900
        X = 3530
        Y = 9
        Width = 317
        Height = 521
    },
    @{
        Title = "dui-005 - TightVNC Viewer"
        Host = "172.21.8.105"
        Password = "admin123456"
        Port = 5900
        X = 1913
        Y = 523
        Width = 335
        Height = 525
    },
    @{
        Title = "dui-023 - TightVNC Viewer"
        Host = "172.21.8.109"
        Password = "admin123456"
        Port = 5900
        X = 2234
        Y = 523
        Width = 331
        Height = 525
    },
    @{
        Title = "dui-014 - TightVNC Viewer"
        Host = "172.21.8.114"
        Password = "admin123456"
        Port = 5900
        X = 2551
        Y = 523
        Width = 336
        Height = 525
    },
    @{
        Title = "dui-007 - TightVNC Viewer"
        Host = "172.21.8.107"
        Password = "admin123456"
        Port = 5900
        X = 2873
        Y = 523
        Width = 336
        Height = 525
    },
    @{
        Title = "dui-021 - TightVNC Viewer"
        Host = "172.21.8.106"
        Password = "admin123456"
        Port = 5900
        X = 3195
        Y = 523
        Width = 349
        Height = 525
    },
    @{
        Title = "dui-016 - TightVNC Viewer"
        Host = "172.21.8.121"
        Password = "admin123456"
        Port = 5900
        X = 3530
        Y = 523
        Width = 317
        Height = 525
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
