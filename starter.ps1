if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Запрос прав администратора..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& {irm https://raw.githubusercontent.com/ngl2n8/all-for-one/main/test.ps1 | iex; Read-Host 'Нажмите Enter для выхода'}`""
    exit
}

$url = "https://raw.githubusercontent.com/ngl2n8/all-for-one/main/test.ps1"
Write-Host "Загрузка скрипта из: $url" -ForegroundColor Cyan
try {
    $script = irm $url
    Write-Host "Выполнение скрипта..." -ForegroundColor Green
    iex $script
}
catch {
    Write-Host "Ошибка: $_" -ForegroundColor Red
    Read-Host "Нажмите Enter для выхода"
}
