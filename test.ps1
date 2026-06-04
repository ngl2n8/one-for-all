Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Создаем основную форму
$form = [System.Windows.Forms.Form]::new()
$form.Text = 'SADOVNIK`s one for all'
$form.Size = '600,500'
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Создаем TabControl для организации функций
$tabControl = [System.Windows.Forms.TabControl]::new()
$tabControl.Location = '10,10'
$tabControl.Size = '565,440'

# ====== Вкладка 1: Очистка папок ======
$tabCleanup = [System.Windows.Forms.TabPage]::new()
$tabCleanup.Text = 'Очистка'
$tabCleanup.BackColor = 'WhiteSmoke'

$labelCleanup = [System.Windows.Forms.Label]::new()
$labelCleanup.Text = 'Путь к папке для очистки:'
$labelCleanup.Location = '20,20'
$labelCleanup.Size = '300,25'

$textBoxPath = [System.Windows.Forms.TextBox]::new()
$textBoxPath.Location = '20,50'
$textBoxPath.Size = '400,25'

$buttonBrowse = [System.Windows.Forms.Button]::new()
$buttonBrowse.Text = 'Обзор...'
$buttonBrowse.Location = '430,49'
$buttonBrowse.Size = '80,27'

$checkBoxSubfolders = [System.Windows.Forms.CheckBox]::new()
$checkBoxSubfolders.Text = 'Включая подпапки'
$checkBoxSubfolders.Location = '20,85'
$checkBoxSubfolders.Size = '200,25'
$checkBoxSubfolders.Checked = $true

$labelFileTypes = [System.Windows.Forms.Label]::new()
$labelFileTypes.Text = 'Типы файлов (через запятую, пусто = все):'
$labelFileTypes.Location = '20,120'
$labelFileTypes.Size = '400,25'

$textBoxFileTypes = [System.Windows.Forms.TextBox]::new()
$textBoxFileTypes.Location = '20,150'
$textBoxFileTypes.Size = '200,25'
$textBoxFileTypes.Text = '*.tmp,*.log,*.bak'

$comboBoxCleanAction = [System.Windows.Forms.ComboBox]::new()
$comboBoxCleanAction.Location = '20,190'
$comboBoxCleanAction.Size = '200,25'
$comboBoxCleanAction.Items.AddRange(@('Удалить файлы', 'Переместить в корзину', 'Показать статистику'))
$comboBoxCleanAction.SelectedIndex = 0

$buttonClean = [System.Windows.Forms.Button]::new()
$buttonClean.Text = 'Выполнить очистку'
$buttonClean.Location = '20,230'
$buttonClean.Size = '150,35'
$buttonClean.BackColor = 'LightCoral'

$labelCleanStatus = [System.Windows.Forms.Label]::new()
$labelCleanStatus.Text = ''
$labelCleanStatus.Location = '20,280'
$labelCleanStatus.Size = '500,100'

$buttonBrowse.Add_Click({
    $folderBrowser = [System.Windows.Forms.FolderBrowserDialog]::new()
    if ($folderBrowser.ShowDialog() -eq 'OK') {
        $textBoxPath.Text = $folderBrowser.SelectedPath
    }
})

$buttonClean.Add_Click({
    $path = $textBoxPath.Text.Trim()
    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Путь не существует!", "Ошибка", 'OK', 'Error')
        return
    }
    
    $fileTypes = if ($textBoxFileTypes.Text) { 
        $textBoxFileTypes.Text.Split(',') | ForEach-Object { $_.Trim() } 
    } else { 
        @('*.*') 
    }
    
    $recurse = $checkBoxSubfolders.Checked
    $action = $comboBoxCleanAction.SelectedItem
    
    try {
        $files = Get-ChildItem -Path $path -Include $fileTypes -Recurse:$recurse -File -ErrorAction Stop
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
        
        switch ($action) {
            'Удалить файлы' {
                $files | Remove-Item -Force
                $labelCleanStatus.Text = "✓ Удалено файлов: $($files.Count)`nОбщий размер: $([math]::Round($totalSize/1MB, 2)) MB"
                $labelCleanStatus.ForeColor = 'Green'
            }
            'Переместить в корзину' {
                $shell = New-Object -ComObject Shell.Application
                foreach ($file in $files) {
                    $shell.Namespace(0).ParseName($file.FullName).InvokeVerb('delete')
                }
                $labelCleanStatus.Text = "✓ Перемещено в корзину: $($files.Count) файлов"
                $labelCleanStatus.ForeColor = 'Green'
            }
            'Показать статистику' {
                $labelCleanStatus.Text = "📊 Найдено файлов: $($files.Count)`nОбщий размер: $([math]::Round($totalSize/1MB, 2)) MB`nТипы: $($textBoxFileTypes.Text)"
                $labelCleanStatus.ForeColor = 'Blue'
            }
        }
    } catch {
        $labelCleanStatus.Text = "✗ Ошибка: $($_.Exception.Message)"
        $labelCleanStatus.ForeColor = 'Red'
    }
})

$tabCleanup.Controls.AddRange(@($labelCleanup, $textBoxPath, $buttonBrowse, $checkBoxSubfolders, $labelFileTypes, $textBoxFileTypes, $comboBoxCleanAction, $buttonClean, $labelCleanStatus))

# ====== Вкладка 2: Системная информация ======
$tabSystem = [System.Windows.Forms.TabPage]::new()
$tabSystem.Text = 'Система'
$tabSystem.BackColor = 'WhiteSmoke'

$textBoxSysInfo = [System.Windows.Forms.TextBox]::new()
$textBoxSysInfo.Location = '10,10'
$textBoxSysInfo.Size = '530,280'
$textBoxSysInfo.Multiline = $true
$textBoxSysInfo.ScrollBars = 'Vertical'
$textBoxSysInfo.ReadOnly = $true
$textBoxSysInfo.Font = 'Consolas, 9'

$buttonRefreshSys = [System.Windows.Forms.Button]::new()
$buttonRefreshSys.Text = 'Обновить информацию'
$buttonRefreshSys.Location = '10,300'
$buttonRefreshSys.Size = '150,30'

$buttonCopyInfo = [System.Windows.Forms.Button]::new()
$buttonCopyInfo.Text = 'Копировать в буфер'
$buttonCopyInfo.Location = '170,300'
$buttonCopyInfo.Size = '150,30'

$buttonRefreshSys.Add_Click({
    $info = @"
Системная информация:
━━━━━━━━━━━━━━━━━━━━━━━━━
Имя компьютера: $env:COMPUTERNAME
Пользователь: $env:USERNAME
ОС: $(Get-CimInstance Win32_OperatingSystem).Caption
Версия: $(Get-CimInstance Win32_OperatingSystem).Version

Аппаратное обеспечение:
━━━━━━━━━━━━━━━━━━━━━━━━━
Процессор: $(Get-CimInstance Win32_Processor | Select-Object -First 1).Name
Ядра: $(Get-CimInstance Win32_Processor | Select-Object -First 1).NumberOfCores
ОЗУ: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB, 2)) GB
Свободно ОЗУ: $([math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB, 2)) GB

Диски:
━━━━━━━━━━━━━━━━━━━━━━━━━
$((Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $free = [math]::Round($_.FreeSpace/1GB, 2)
    $total = [math]::Round($_.Size/1GB, 2)
    "$($_.DeviceID)\ Свободно: $free GB из $total GB"
}) -join "`n")

Время работы: $((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime | Select-Object -ExpandProperty Days) дней
"@
    $textBoxSysInfo.Text = $info
})

$buttonCopyInfo.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($textBoxSysInfo.Text)
    [System.Windows.Forms.MessageBox]::Show("Информация скопирована в буфер обмена!", "Успех")
})

$tabSystem.Controls.AddRange(@($textBoxSysInfo, $buttonRefreshSys, $buttonCopyInfo))

# ====== Вкладка 3: Процессы ======
$tabProcesses = [System.Windows.Forms.TabPage]::new()
$tabProcesses.Text = 'Процессы'
$tabProcesses.BackColor = 'WhiteSmoke'

$labelProcSearch = [System.Windows.Forms.Label]::new()
$labelProcSearch.Text = 'Поиск процесса:'
$labelProcSearch.Location = '10,10'
$labelProcSearch.Size = '150,25'

$textBoxProcSearch = [System.Windows.Forms.TextBox]::new()
$textBoxProcSearch.Location = '10,35'
$textBoxProcSearch.Size = '200,25'

$buttonProcSearch = [System.Windows.Forms.Button]::new()
$buttonProcSearch.Text = 'Найти'
$buttonProcSearch.Location = '220,34'
$buttonProcSearch.Size = '80,27'

$listBoxProcesses = [System.Windows.Forms.ListBox]::new()
$listBoxProcesses.Location = '10,70'
$listBoxProcesses.Size = '300,250'
$listBoxProcesses.Font = 'Consolas, 9'

$buttonKillProcess = [System.Windows.Forms.Button]::new()
$buttonKillProcess.Text = 'Завершить процесс'
$buttonKillProcess.Location = '320,70'
$buttonKillProcess.Size = '120,30'
$buttonKillProcess.BackColor = 'LightCoral'

$labelProcInfo = [System.Windows.Forms.Label]::new()
$labelProcInfo.Text = 'Выберите процесс'
$labelProcInfo.Location = '320,110'
$labelProcInfo.Size = '200,200'

$buttonRefreshProc = [System.Windows.Forms.Button]::new()
$buttonRefreshProc.Text = 'Обновить список'
$buttonRefreshProc.Location = '320,35'
$buttonRefreshProc.Size = '120,27'

$buttonProcSearch.Add_Click({
    $searchTerm = $textBoxProcSearch.Text
    $listBoxProcesses.Items.Clear()
    Get-Process | Where-Object { $_.ProcessName -like "*$searchTerm*" } | Sort-Object ProcessName | ForEach-Object {
        $listBoxProcesses.Items.Add("$($_.ProcessName) (PID: $($_.Id))")
    }
})

$buttonRefreshProc.Add_Click({
    $listBoxProcesses.Items.Clear()
    Get-Process | Sort-Object ProcessName | ForEach-Object {
        $listBoxProcesses.Items.Add("$($_.ProcessName) (PID: $($_.Id))")
    }
})

$listBoxProcesses.Add_SelectedIndexChanged({
    if ($listBoxProcesses.SelectedItem) {
        $procName = ($listBoxProcesses.SelectedItem -split ' \(PID: ')[0]
        $proc = Get-Process -Name $procName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($proc) {
            $labelProcInfo.Text = "Имя: $($proc.ProcessName)`nPID: $($proc.Id)`nОЗУ: $([math]::Round($proc.WorkingSet64/1MB, 2)) MB`nПотоки: $($proc.Threads.Count)`nЗапущен: $($proc.StartTime)"
        }
    }
})

$buttonKillProcess.Add_Click({
    if ($listBoxProcesses.SelectedItem) {
        $procName = ($listBoxProcesses.SelectedItem -split ' \(PID: ')[0]
        $result = [System.Windows.Forms.MessageBox]::Show("Завершить процесс $procName?", "Подтверждение", 'YesNo', 'Warning')
        if ($result -eq 'Yes') {
            try {
                Stop-Process -Name $procName -Force -ErrorAction Stop
                [System.Windows.Forms.MessageBox]::Show("Процесс $procName завершен", "Успех")
                $buttonRefreshProc.PerformClick()
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Ошибка: $($_.Exception.Message)", "Ошибка", 'OK', 'Error')
            }
        }
    }
})

$tabProcesses.Controls.AddRange(@($labelProcSearch, $textBoxProcSearch, $buttonProcSearch, $listBoxProcesses, $buttonKillProcess, $labelProcInfo, $buttonRefreshProc))

# ====== Вкладка 4: Сеть ======
$tabNetwork = [System.Windows.Forms.TabPage]::new()
$tabNetwork.Text = 'Сеть'
$tabNetwork.BackColor = 'WhiteSmoke'

$textBoxNetworkInfo = [System.Windows.Forms.TextBox]::new()
$textBoxNetworkInfo.Location = '10,10'
$textBoxNetworkInfo.Size = '530,250'
$textBoxNetworkInfo.Multiline = $true
$textBoxNetworkInfo.ScrollBars = 'Vertical'
$textBoxNetworkInfo.ReadOnly = $true
$textBoxNetworkInfo.Font = 'Consolas, 9'

$buttonNetInfo = [System.Windows.Forms.Button]::new()
$buttonNetInfo.Text = 'Сетевая информация'
$buttonNetInfo.Location = '10,270'
$buttonNetInfo.Size = '150,30'

$buttonPing = [System.Windows.Forms.Button]::new()
$buttonPing.Text = 'Пинг (google.com)'
$buttonPing.Location = '170,270'
$buttonPing.Size = '150,30'

$buttonConnections = [System.Windows.Forms.Button]::new()
$buttonConnections.Text = 'Активные соединения'
$buttonConnections.Location = '330,270'
$buttonConnections.Size = '150,30'

$buttonNetInfo.Add_Click({
    $networkInfo = @"
Сетевые адаптеры:
━━━━━━━━━━━━━━━━━━━━━━━━━
$((Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
    $ip = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress
    "$($_.Name): $ip ($($_.InterfaceDescription))"
}) -join "`n")

DNS серверы:
━━━━━━━━━━━━━━━━━━━━━━━━━
$((Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses -ne $null | ForEach-Object {
    "$($_.InterfaceAlias): $($_.ServerAddresses -join ', ')"
}) -join "`n")
"@
    $textBoxNetworkInfo.Text = $networkInfo
})

$buttonPing.Add_Click({
    $textBoxNetworkInfo.Text = "Пинг google.com...`r`n"
    try {
        $ping = Test-Connection -ComputerName google.com -Count 2 -ErrorAction Stop
        foreach ($p in $ping) {
            $textBoxNetworkInfo.Text += "Ответ от $($p.Address): time=$($p.ResponseTime)ms`r`n"
        }
    } catch {
        $textBoxNetworkInfo.Text += "Ошибка пинга: $($_.Exception.Message)"
    }
})

$buttonConnections.Add_Click({
    $textBoxNetworkInfo.Text = "Активные TCP соединения (первые 20):`r`n"
    Get-NetTCPConnection -State Established | Select-Object -First 20 | ForEach-Object {
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        $textBoxNetworkInfo.Text += "$($_.LocalAddress):$($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort) [$($proc.ProcessName)]`r`n"
    }
})

$tabNetwork.Controls.AddRange(@($textBoxNetworkInfo, $buttonNetInfo, $buttonPing, $buttonConnections))

# Добавляем вкладки в TabControl
$tabControl.Controls.AddRange(@($tabCleanup, $tabSystem, $tabProcesses, $tabNetwork))

# Добавляем TabControl на форму
$form.Controls.Add($tabControl)

# Показываем форму
$form.Topmost = $true
$buttonRefreshSys.PerformClick()
$form.ShowDialog()
