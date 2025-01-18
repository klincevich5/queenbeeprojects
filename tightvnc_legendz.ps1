
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
$windowData = @(
    @{
        Title = "dui-026 - TightVNC Viewer"
        Host = "172.21.8.126"
        Password = "admin123456"
        Port = 5900
        X = 1913
        Y = 0
        Width = 974
        Height = 351
    },
    @{
        Title = "dui-027 - TightVNC Viewer"
        Host = "172.21.8.127"
        Password = "admin123456"
        Port = 5900
        X = 2873
        Y = 0
        Width = 974
        Height = 351
    },
    @{
        Title = "dui-038 - TightVNC Viewer"
        Host = "172.21.8.141"
        Password = "admin123456"
        Port = 5900
        X = 1913
        Y = 344
        Width = 494
        Height = 351
    },
    @{
        Title = "dui-039 - TightVNC Viewer"
        Host = "172.21.8.143"
        Password = "admin123456"
        Port = 5900
        X = 2393
        Y = 344
        Width = 494
        Height = 351
    },
    @{
        Title = "dui-037 - TightVNC Viewer"
        Host = "172.21.8.140"
        Password = "admin123456"
        Port = 5900
        X = 2873
        Y = 344
        Width = 494
        Height = 351
    },
    @{
        Title = "dui-034 - TightVNC Viewer"
        Host = "172.21.8.134"
        Password = "admin123456"
        Port = 5900
        X = 1913
        Y = 688
        Width = 494
        Height = 351
    },
    @{
        Title = "vicoder - TightVNC Viewer"
        Host = "172.21.8.132"
        Password = "admin123456"
        Port = 5900
        X = 2393
        Y = 688
        Width = 494
        Height = 351
    },
    @{
        Title = "dui-036 - TightVNC Viewer"
        Host = "172.21.8.136"
        Password = "admin123456"
        Port = 5900
        X = 2873
        Y = 688
        Width = 494
        Height = 351
    },
    @{
        Title = "dui-017 - TightVNC Viewer"
        Host = "172.21.8.117"
        Password = "admin123456"
        Port = 5900
        X = 3353
        Y = 688
        Width = 494
        Height = 351
    },
    @{
        Title = "dui-031 - TightVNC Viewer"
        Host = "172.21.8.131"
        Password = "admin123456"
        Port = 5900
        X = 3353
        Y = 344
        Width = 494
        Height = 351
    },
)

# Проверка окон и запуск/перемещение
foreach ($window in $windowData) {
    $title = $window.Title
    $remoteHost = $window.Host
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
        $args = @("${remoteHost}::${port}", "-password=${password}")
        try {
            Write-Host "Запуск нового экземпляра TightVNC Viewer для '$title'..."
            Start-Process -FilePath $tightVncPath -ArgumentList $args -NoNewWindow -ErrorAction Stop
            Start-Sleep -Seconds 2

            # Повторяем попытку поиска окна с ожиданием
            $newProcess = $null
            $retryCount = 0
            while ($retryCount -lt 3) {
                $newProcess = Get-Process -Name "tvnviewer" | Where-Object { $_.MainWindowTitle -eq $title }
                if ($newProcess) {
                    break
                }
                $retryCount++
                Start-Sleep -Seconds 3
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
