Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = [System.Windows.Forms.Form]::new()
$form.Text = 'PowerShell Swiss Army Knife'
$form.Size = '700,550'
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$tabControl = [System.Windows.Forms.TabControl]::new()
$tabControl.Location = '10,10'
$tabControl.Size = '665,490'

$tabCleanup = [System.Windows.Forms.TabPage]::new()
$tabCleanup.Text = 'Очистка'
$tabCleanup.BackColor = 'WhiteSmoke'

$labelCleanup = [System.Windows.Forms.Label]::new()
$labelCleanup.Text = 'Путь к папке для очистки:'
$labelCleanup.Location = '20,20'
$labelCleanup.Size = '300,25'

$textBoxPath = [System.Windows.Forms.TextBox]::new()
$textBoxPath.Location = '20,50'
$textBoxPath.Size = '450,25'

$buttonBrowse = [System.Windows.Forms.Button]::new()
$buttonBrowse.Text = 'Обзор...'
$buttonBrowse.Location = '480,49'
$buttonBrowse.Size = '80,27'

$checkBoxSubfolders = [System.Windows.Forms.CheckBox]::new()
$checkBoxSubfolders.Text = 'Включая подпапки'
$checkBoxSubfolders.Location = '20,85'
$checkBoxSubfolders.Size = '200,25'
$checkBoxSubfolders.Checked = $true

$checkBoxOlderThan = [System.Windows.Forms.CheckBox]::new()
$checkBoxOlderThan.Text = 'Старше (дней):'
$checkBoxOlderThan.Location = '240,85'
$checkBoxOlderThan.Size = '120,25'

$numericUpDownDays = [System.Windows.Forms.NumericUpDown]::new()
$numericUpDownDays.Location = '360,85'
$numericUpDownDays.Size = '60,25'
$numericUpDownDays.Minimum = 1
$numericUpDownDays.Maximum = 3650
$numericUpDownDays.Value = 30

$labelFileTypes = [System.Windows.Forms.Label]::new()
$labelFileTypes.Text = 'Типы файлов (через запятую, пусто = все):'
$labelFileTypes.Location = '20,120'
$labelFileTypes.Size = '400,25'

$textBoxFileTypes = [System.Windows.Forms.TextBox]::new()
$textBoxFileTypes.Location = '20,150'
$textBoxFileTypes.Size = '250,25'
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
$labelCleanStatus.Size = '620,160'

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
    $olderThan = if ($checkBoxOlderThan.Checked) { (Get-Date).AddDays(-$numericUpDownDays.Value) } else { $null }
    
    try {
        $files = Get-ChildItem -Path $path -Include $fileTypes -Recurse:$recurse -File -ErrorAction Stop
        if ($olderThan) {
            $files = $files | Where-Object { $_.LastWriteTime -lt $olderThan }
        }
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
                $labelCleanStatus.Text = "📊 Найдено файлов: $($files.Count)`nОбщий размер: $([math]::Round($totalSize/1MB, 2)) MB`nТипы: $($textBoxFileTypes.Text)`nСтарше $($numericUpDownDays.Value) дней: $($checkBoxOlderThan.Checked)"
                $labelCleanStatus.ForeColor = 'Blue'
            }
        }
    } catch {
        $labelCleanStatus.Text = "✗ Ошибка: $($_.Exception.Message)"
        $labelCleanStatus.ForeColor = 'Red'
    }
})

$tabCleanup.Controls.AddRange(@($labelCleanup, $textBoxPath, $buttonBrowse, $checkBoxSubfolders, $checkBoxOlderThan, $numericUpDownDays, $labelFileTypes, $textBoxFileTypes, $comboBoxCleanAction, $buttonClean, $labelCleanStatus))

$tabSystem = [System.Windows.Forms.TabPage]::new()
$tabSystem.Text = 'Система'
$tabSystem.BackColor = 'WhiteSmoke'

$textBoxSysInfo = [System.Windows.Forms.TextBox]::new()
$textBoxSysInfo.Location = '10,10'
$textBoxSysInfo.Size = '635,280'
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

$buttonExportSys = [System.Windows.Forms.Button]::new()
$buttonExportSys.Text = 'Экспорт в файл'
$buttonExportSys.Location = '330,300'
$buttonExportSys.Size = '150,30'

$buttonRefreshSys.Add_Click({
    $info = @"
Системная информация:
━━━━━━━━━━━━━━━━━━━━━━━━━
Имя компьютера: $env:COMPUTERNAME
Пользователь: $env:USERNAME
ОС: $(Get-CimInstance Win32_OperatingSystem).Caption
Версия: $(Get-CimInstance Win32_OperatingSystem).Version
Архитектура: $(Get-CimInstance Win32_OperatingSystem).OSArchitecture
Последняя загрузка: $(Get-CimInstance Win32_OperatingSystem).LastBootUpTime

Аппаратное обеспечение:
━━━━━━━━━━━━━━━━━━━━━━━━━
Процессор: $(Get-CimInstance Win32_Processor | Select-Object -First 1).Name
Ядра: $(Get-CimInstance Win32_Processor | Select-Object -First 1).NumberOfCores
Логические процессоры: $(Get-CimInstance Win32_Processor | Select-Object -First 1).NumberOfLogicalProcessors
ОЗУ: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB, 2)) GB
Свободно ОЗУ: $([math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB, 2)) GB
Видеокарта: $(Get-CimInstance Win32_VideoController | Select-Object -First 1).Name

Диски:
━━━━━━━━━━━━━━━━━━━━━━━━━
$((Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $free = [math]::Round($_.FreeSpace/1GB, 2)
    $total = [math]::Round($_.Size/1GB, 2)
    $percentFree = [math]::Round(($_.FreeSpace/$_.Size)*100, 1)
    "$($_.DeviceID)\ $free GB свободно из $total GB ($percentFree%)"
}) -join "`n")

Время работы: $(((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).Days) дней $(((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).Hours) часов
"@
    $textBoxSysInfo.Text = $info
})

$buttonCopyInfo.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($textBoxSysInfo.Text)
    [System.Windows.Forms.MessageBox]::Show("Информация скопирована в буфер обмена!", "Успех")
})

$buttonExportSys.Add_Click({
    $saveFileDialog = [System.Windows.Forms.SaveFileDialog]::new()
    $saveFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $saveFileDialog.FileName = "system_info_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    if ($saveFileDialog.ShowDialog() -eq 'OK') {
        $textBoxSysInfo.Text | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Информация сохранена в файл!", "Успех")
    }
})

$tabSystem.Controls.AddRange(@($textBoxSysInfo, $buttonRefreshSys, $buttonCopyInfo, $buttonExportSys))

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
$listBoxProcesses.Size = '350,250'
$listBoxProcesses.Font = 'Consolas, 9'

$buttonKillProcess = [System.Windows.Forms.Button]::new()
$buttonKillProcess.Text = 'Завершить процесс'
$buttonKillProcess.Location = '370,70'
$buttonKillProcess.Size = '140,30'
$buttonKillProcess.BackColor = 'LightCoral'

$buttonProcDetails = [System.Windows.Forms.Button]::new()
$buttonProcDetails.Text = 'Подробнее'
$buttonProcDetails.Location = '370,110'
$buttonProcDetails.Size = '140,30'

$buttonExportProc = [System.Windows.Forms.Button]::new()
$buttonExportProc.Text = 'Экспорт списка'
$buttonExportProc.Location = '370,150'
$buttonExportProc.Size = '140,30'

$labelProcInfo = [System.Windows.Forms.Label]::new()
$labelProcInfo.Text = 'Выберите процесс'
$labelProcInfo.Location = '370,190'
$labelProcInfo.Size = '270,130'

$buttonRefreshProc = [System.Windows.Forms.Button]::new()
$buttonRefreshProc.Text = 'Обновить список'
$buttonRefreshProc.Location = '520,34'
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
            $labelProcInfo.Text = "Имя: $($proc.ProcessName)`nPID: $($proc.Id)`nОЗУ: $([math]::Round($proc.WorkingSet64/1MB, 2)) MB`nПотоки: $($proc.Threads.Count)`nЗапущен: $($proc.StartTime)`nПроцессорное время: $($proc.TotalProcessorTime)"
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

$buttonProcDetails.Add_Click({
    if ($listBoxProcesses.SelectedItem) {
        $procName = ($listBoxProcesses.SelectedItem -split ' \(PID: ')[0]
        $proc = Get-Process -Name $procName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($proc) {
            $details = "Process: $($proc.ProcessName)`n"
            $details += "ID: $($proc.Id)`n"
            $details += "Session ID: $($proc.SessionId)`n"
            $details += "Priority: $($proc.PriorityClass)`n"
            $details += "Memory: $([math]::Round($proc.WorkingSet64/1MB, 2)) MB`n"
            $details += "Virtual Memory: $([math]::Round($proc.VirtualMemorySize64/1MB, 2)) MB`n"
            $details += "Threads: $($proc.Threads.Count)`n"
            $details += "Handles: $($proc.HandleCount)`n"
            $details += "Start Time: $($proc.StartTime)`n"
            $details += "CPU Time: $($proc.TotalProcessorTime)`n"
            $details += "Company: $($proc.Company)`n"
            $details += "Description: $($proc.Description)`n"
            $details += "Path: $($proc.Path)"
            [System.Windows.Forms.MessageBox]::Show($details, "Детали процесса", 'OK', 'Information')
        }
    }
})

$buttonExportProc.Add_Click({
    $saveFileDialog = [System.Windows.Forms.SaveFileDialog]::new()
    $saveFileDialog.Filter = "CSV files (*.csv)|*.csv|Text files (*.txt)|*.txt"
    $saveFileDialog.FileName = "processes_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    if ($saveFileDialog.ShowDialog() -eq 'OK') {
        Get-Process | Select-Object Name, Id, @{N='MemoryMB';E={[math]::Round($_.WorkingSet64/1MB, 2)}}, StartTime, Threads | Export-Csv -Path $saveFileDialog.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Список процессов экспортирован!", "Успех")
    }
})

$tabProcesses.Controls.AddRange(@($labelProcSearch, $textBoxProcSearch, $buttonProcSearch, $listBoxProcesses, $buttonKillProcess, $buttonProcDetails, $buttonExportProc, $labelProcInfo, $buttonRefreshProc))

$tabNetwork = [System.Windows.Forms.TabPage]::new()
$tabNetwork.Text = 'Сеть'
$tabNetwork.BackColor = 'WhiteSmoke'

$textBoxNetworkInfo = [System.Windows.Forms.TextBox]::new()
$textBoxNetworkInfo.Location = '10,10'
$textBoxNetworkInfo.Size = '635,250'
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

$textBoxCustomPing = [System.Windows.Forms.TextBox]::new()
$textBoxCustomPing.Location = '330,272'
$textBoxCustomPing.Size = '150,25'
$textBoxCustomPing.Text = 'google.com'

$buttonCustomPing = [System.Windows.Forms.Button]::new()
$buttonCustomPing.Text = 'Пинг'
$buttonCustomPing.Location = '490,270'
$buttonCustomPing.Size = '75,27'

$buttonConnections = [System.Windows.Forms.Button]::new()
$buttonConnections.Text = 'Активные соединения'
$buttonConnections.Location = '10,310'
$buttonConnections.Size = '150,30'

$buttonDnsLookup = [System.Windows.Forms.Button]::new()
$buttonDnsLookup.Text = 'DNS запрос'
$buttonDnsLookup.Location = '170,310'
$buttonDnsLookup.Size = '150,30'

$buttonTraceRoute = [System.Windows.Forms.Button]::new()
$buttonTraceRoute.Text = 'Трассировка'
$buttonTraceRoute.Location = '330,310'
$buttonTraceRoute.Size = '150,30'

$buttonNetInfo.Add_Click({
    $networkInfo = @"
Сетевые адаптеры:
━━━━━━━━━━━━━━━━━━━━━━━━━
$((Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
    $ip = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress
    "$($_.Name): $ip ($($_.InterfaceDescription))`nСкорость: $($_.LinkSpeed)"
}) -join "`n`n")

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
        $ping = Test-Connection -ComputerName google.com -Count 4 -ErrorAction Stop
        foreach ($p in $ping) {
            $textBoxNetworkInfo.Text += "Ответ от $($p.Address): time=$($p.ResponseTime)ms`r`n"
        }
        $avg = ($ping | Measure-Object -Property ResponseTime -Average).Average
        $textBoxNetworkInfo.Text += "`r`nСреднее время: $([math]::Round($avg))ms"
    } catch {
        $textBoxNetworkInfo.Text += "Ошибка пинга: $($_.Exception.Message)"
    }
})

$buttonCustomPing.Add_Click({
    $hostname = $textBoxCustomPing.Text.Trim()
    if ($hostname) {
        $textBoxNetworkInfo.Text = "Пинг ${hostname}...`r`n"
        try {
            $ping = Test-Connection -ComputerName $hostname -Count 4 -ErrorAction Stop
            foreach ($p in $ping) {
                $textBoxNetworkInfo.Text += "Ответ от $($p.Address): time=$($p.ResponseTime)ms`r`n"
            }
        } catch {
            $textBoxNetworkInfo.Text += "Ошибка пинга: $($_.Exception.Message)"
        }
    }
})

$buttonConnections.Add_Click({
    $textBoxNetworkInfo.Text = "Активные TCP соединения (первые 30):`r`n"
    Get-NetTCPConnection -State Established | Select-Object -First 30 | ForEach-Object {
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        $textBoxNetworkInfo.Text += "$($_.LocalAddress):$($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort) [$($proc.ProcessName)]`r`n"
    }
})

$buttonDnsLookup.Add_Click({
    $hostname = $textBoxCustomPing.Text.Trim()
    if ($hostname) {
        $textBoxNetworkInfo.Text = "DNS запрос для ${hostname}:`r`n"
        try {
            $dns = Resolve-DnsName -Name $hostname -ErrorAction Stop
            $dns | ForEach-Object {
                $textBoxNetworkInfo.Text += "$($_.Name) -> $($_.IPAddress) (Type: $($_.Type))`r`n"
            }
        } catch {
            $textBoxNetworkInfo.Text += "Ошибка DNS: $($_.Exception.Message)"
        }
    }
})

$buttonTraceRoute.Add_Click({
    $hostname = $textBoxCustomPing.Text.Trim()
    if ($hostname) {
        $textBoxNetworkInfo.Text = "Трассировка до ${hostname}:`r`n"
        try {
            $trace = Test-NetConnection -ComputerName $hostname -TraceRoute -ErrorAction Stop
            $hopNum = 1
            foreach ($hop in $trace.TraceRoute) {
                $textBoxNetworkInfo.Text += "$hopNum`t$hop`r`n"
                $hopNum++
            }
        } catch {
            $textBoxNetworkInfo.Text += "Ошибка трассировки: $($_.Exception.Message)"
        }
    }
})

$tabNetwork.Controls.AddRange(@($textBoxNetworkInfo, $buttonNetInfo, $buttonPing, $textBoxCustomPing, $buttonCustomPing, $buttonConnections, $buttonDnsLookup, $buttonTraceRoute))

$tabServices = [System.Windows.Forms.TabPage]::new()
$tabServices.Text = 'Службы'
$tabServices.BackColor = 'WhiteSmoke'

$labelServiceSearch = [System.Windows.Forms.Label]::new()
$labelServiceSearch.Text = 'Поиск службы:'
$labelServiceSearch.Location = '10,10'
$labelServiceSearch.Size = '150,25'

$textBoxServiceSearch = [System.Windows.Forms.TextBox]::new()
$textBoxServiceSearch.Location = '10,35'
$textBoxServiceSearch.Size = '200,25'

$buttonServiceSearch = [System.Windows.Forms.Button]::new()
$buttonServiceSearch.Text = 'Найти'
$buttonServiceSearch.Location = '220,34'
$buttonServiceSearch.Size = '80,27'

$listBoxServices = [System.Windows.Forms.ListBox]::new()
$listBoxServices.Location = '10,70'
$listBoxServices.Size = '350,300'
$listBoxServices.Font = 'Consolas, 9'

$buttonStartService = [System.Windows.Forms.Button]::new()
$buttonStartService.Text = 'Запустить'
$buttonStartService.Location = '370,70'
$buttonStartService.Size = '140,30'
$buttonStartService.BackColor = 'LightGreen'

$buttonStopService = [System.Windows.Forms.Button]::new()
$buttonStopService.Text = 'Остановить'
$buttonStopService.Location = '370,110'
$buttonStopService.Size = '140,30'
$buttonStopService.BackColor = 'LightCoral'

$buttonRestartService = [System.Windows.Forms.Button]::new()
$buttonRestartService.Text = 'Перезапустить'
$buttonRestartService.Location = '370,150'
$buttonRestartService.Size = '140,30'
$buttonRestartService.BackColor = 'LightYellow'

$buttonServiceDetails = [System.Windows.Forms.Button]::new()
$buttonServiceDetails.Text = 'Подробнее'
$buttonServiceDetails.Location = '370,190'
$buttonServiceDetails.Size = '140,30'

$labelServiceInfo = [System.Windows.Forms.Label]::new()
$labelServiceInfo.Text = 'Выберите службу'
$labelServiceInfo.Location = '370,230'
$labelServiceInfo.Size = '270,140'

$buttonRefreshServices = [System.Windows.Forms.Button]::new()
$buttonRefreshServices.Text = 'Обновить список'
$buttonRefreshServices.Location = '520,34'
$buttonRefreshServices.Size = '120,27'

$buttonServiceSearch.Add_Click({
    $searchTerm = $textBoxServiceSearch.Text
    $listBoxServices.Items.Clear()
    Get-Service | Where-Object { $_.Name -like "*$searchTerm*" -or $_.DisplayName -like "*$searchTerm*" } | Sort-Object Name | ForEach-Object {
        $listBoxServices.Items.Add("$($_.Name) [$($_.Status)]")
    }
})

$buttonRefreshServices.Add_Click({
    $listBoxServices.Items.Clear()
    Get-Service | Sort-Object Name | ForEach-Object {
        $listBoxServices.Items.Add("$($_.Name) [$($_.Status)]")
    }
})

$listBoxServices.Add_SelectedIndexChanged({
    if ($listBoxServices.SelectedItem) {
        $serviceName = ($listBoxServices.SelectedItem -split ' \[')[0]
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $labelServiceInfo.Text = "Имя: $($service.Name)`nОтображаемое имя: $($service.DisplayName)`nСтатус: $($service.Status)`nТип запуска: $($service.StartType)`nОписание: $($service.Description)"
        }
    }
})

$buttonStartService.Add_Click({
    if ($listBoxServices.SelectedItem) {
        $serviceName = ($listBoxServices.SelectedItem -split ' \[')[0]
        try {
            Start-Service -Name $serviceName -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show("Служба $serviceName запущена", "Успех")
            $buttonRefreshServices.PerformClick()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Ошибка: $($_.Exception.Message)", "Ошибка", 'OK', 'Error')
        }
    }
})

$buttonStopService.Add_Click({
    if ($listBoxServices.SelectedItem) {
        $serviceName = ($listBoxServices.SelectedItem -split ' \[')[0]
        $result = [System.Windows.Forms.MessageBox]::Show("Остановить службу $serviceName?", "Подтверждение", 'YesNo', 'Warning')
        if ($result -eq 'Yes') {
            try {
                Stop-Service -Name $serviceName -Force -ErrorAction Stop
                [System.Windows.Forms.MessageBox]::Show("Служба $serviceName остановлена", "Успех")
                $buttonRefreshServices.PerformClick()
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Ошибка: $($_.Exception.Message)", "Ошибка", 'OK', 'Error')
            }
        }
    }
})

$buttonRestartService.Add_Click({
    if ($listBoxServices.SelectedItem) {
        $serviceName = ($listBoxServices.SelectedItem -split ' \[')[0]
        $result = [System.Windows.Forms.MessageBox]::Show("Перезапустить службу $serviceName?", "Подтверждение", 'YesNo', 'Warning')
        if ($result -eq 'Yes') {
            try {
                Restart-Service -Name $serviceName -Force -ErrorAction Stop
                [System.Windows.Forms.MessageBox]::Show("Служба $serviceName перезапущена", "Успех")
                $buttonRefreshServices.PerformClick()
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Ошибка: $($_.Exception.Message)", "Ошибка", 'OK', 'Error')
            }
        }
    }
})

$buttonServiceDetails.Add_Click({
    if ($listBoxServices.SelectedItem) {
        $serviceName = ($listBoxServices.SelectedItem -split ' \[')[0]
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $wmiService = Get-CimInstance Win32_Service -Filter "Name='$serviceName'"
            $details = "Service Details:`n`n"
            $details += "Name: $($service.Name)`n"
            $details += "Display Name: $($service.DisplayName)`n"
            $details += "Status: $($service.Status)`n"
            $details += "Start Type: $($service.StartType)`n"
            $details += "Path: $($wmiService.PathName)`n"
            $details += "Process ID: $($wmiService.ProcessId)`n"
            $details += "Start Mode: $($wmiService.StartMode)`n"
            $details += "Description: $($service.Description)"
            [System.Windows.Forms.MessageBox]::Show($details, "Детали службы", 'OK', 'Information')
        }
    }
})

$tabServices.Controls.AddRange(@($labelServiceSearch, $textBoxServiceSearch, $buttonServiceSearch, $listBoxServices, $buttonStartService, $buttonStopService, $buttonRestartService, $buttonServiceDetails, $labelServiceInfo, $buttonRefreshServices))

$tabRegistry = [System.Windows.Forms.TabPage]::new()
$tabRegistry.Text = 'Реестр'
$tabRegistry.BackColor = 'WhiteSmoke'

$labelRegPath = [System.Windows.Forms.Label]::new()
$labelRegPath.Text = 'Путь в реестре:'
$labelRegPath.Location = '10,10'
$labelRegPath.Size = '400,25'

$textBoxRegPath = [System.Windows.Forms.TextBox]::new()
$textBoxRegPath.Location = '10,35'
$textBoxRegPath.Size = '400,25'
$textBoxRegPath.Text = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'

$buttonRegRead = [System.Windows.Forms.Button]::new()
$buttonRegRead.Text = 'Читать'
$buttonRegRead.Location = '420,34'
$buttonRegRead.Size = '100,27'

$buttonRegDelete = [System.Windows.Forms.Button]::new()
$buttonRegDelete.Text = 'Удалить'
$buttonRegDelete.Location = '530,34'
$buttonRegDelete.Size = '100,27'
$buttonRegDelete.BackColor = 'LightCoral'

$textBoxRegResult = [System.Windows.Forms.TextBox]::new()
$textBoxRegResult.Location = '10,70'
$textBoxRegResult.Size = '635,280'
$textBoxRegResult.Multiline = $true
$textBoxRegResult.ScrollBars = 'Vertical'
$textBoxRegResult.ReadOnly = $true
$textBoxRegResult.Font = 'Consolas, 9'

$buttonRegExport = [System.Windows.Forms.Button]::new()
$buttonRegExport.Text = 'Экспорт'
$buttonRegExport.Location = '10,360'
$buttonRegExport.Size = '100,30'

$buttonRegBackup = [System.Windows.Forms.Button]::new()
$buttonRegBackup.Text = 'Бэкап ветки'
$buttonRegBackup.Location = '120,360'
$buttonRegBackup.Size = '100,30'

$buttonRegQuickAccess = [System.Windows.Forms.Button]::new()
$buttonRegQuickAccess.Text = 'Быстрый доступ'
$buttonRegQuickAccess.Location = '230,360'
$buttonRegQuickAccess.Size = '120,30'

$quickAccessMenu = [System.Windows.Forms.ContextMenuStrip]::new()
$quickAccessItems = @(
    @{Text='Автозагрузка (Current User)'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'},
    @{Text='Автозагрузка (Local Machine)'; Path='HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'},
    @{Text='Проводник'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'},
    @{Text='Контекстное меню'; Path='HKCU:\Software\Classes\*\shell'},
    @{Text='Настройки рабочего стола'; Path='HKCU:\Control Panel\Desktop'}
)

foreach ($item in $quickAccessItems) {
    $menuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuItem.Text = $item.Text
    $menuItem.Tag = $item.Path
    $menuItem.Add_Click({
        $textBoxRegPath.Text = $this.Tag
        $buttonRegRead.PerformClick()
    })
    $quickAccessMenu.Items.Add($menuItem)
}

$buttonRegQuickAccess.Add_Click({
    $quickAccessMenu.Show($buttonRegQuickAccess, 0, $buttonRegQuickAccess.Height)
})

$buttonRegRead.Add_Click({
    $regPath = $textBoxRegPath.Text.Trim()
    if ($regPath) {
        try {
            $regItems = Get-Item -Path $regPath -ErrorAction Stop
            $textBoxRegResult.Text = "Путь: $regPath`r`n`r`n"
            $textBoxRegResult.Text += "Подразделы:`r`n"
            $regItems.GetSubKeyNames() | ForEach-Object {
                $textBoxRegResult.Text += "  [$_]`r`n"
            }
            $textBoxRegResult.Text += "`r`nЗначения:`r`n"
            foreach ($prop in $regItems.Property) {
                $value = $regItems.GetValue($prop)
                if ($value -is [byte[]]) {
                    $value = "0x$([System.BitConverter]::ToString($value) -replace '-',',0x')"
                }
                $textBoxRegResult.Text += "  $prop`: $value ($($regItems.GetValueKind($prop)))`r`n"
            }
        } catch {
            $textBoxRegResult.Text = "Ошибка: $($_.Exception.Message)"
        }
    }
})

$buttonRegDelete.Add_Click({
    $regPath = $textBoxRegPath.Text.Trim()
    if ($regPath) {
        $result = [System.Windows.Forms.MessageBox]::Show("Удалить ветку реестра $regPath?`nЭто действие необратимо!", "Опасно!", 'YesNo', 'Warning')
        if ($result -eq 'Yes') {
            try {
                Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
                $textBoxRegResult.Text = "Ветка $regPath успешно удалена"
                [System.Windows.Forms.MessageBox]::Show("Ветка реестра удалена", "Успех")
            } catch {
                $textBoxRegResult.Text = "Ошибка удаления: $($_.Exception.Message)"
            }
        }
    }
})

$buttonRegExport.Add_Click({
    $regPath = $textBoxRegPath.Text.Trim()
    if ($regPath) {
        $saveFileDialog = [System.Windows.Forms.SaveFileDialog]::new()
        $saveFileDialog.Filter = "Registry files (*.reg)|*.reg"
        $saveFileDialog.FileName = "registry_export_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        if ($saveFileDialog.ShowDialog() -eq 'OK') {
            try {
                reg export $($regPath -replace 'HKCU:', 'HKEY_CURRENT_USER' -replace 'HKLM:', 'HKEY_LOCAL_MACHINE' -replace 'HKCR:', 'HKEY_CLASSES_ROOT' -replace 'HKU:', 'HKEY_USERS' -replace 'HKCC:', 'HKEY_CURRENT_CONFIG') $saveFileDialog.FileName
                [System.Windows.Forms.MessageBox]::Show("Ветка реестра экспортирована в .reg файл", "Успех")
            } catch {
                $textBoxRegResult.Text = "Ошибка экспорта: $($_.Exception.Message)"
            }
        }
    }
})

$buttonRegBackup.Add_Click({
    $regPath = $textBoxRegPath.Text.Trim()
    if ($regPath) {
        $saveFileDialog = [System.Windows.Forms.SaveFileDialog]::new()
        $saveFileDialog.Filter = "Registry files (*.reg)|*.reg"
        $saveFileDialog.FileName = "registry_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        if ($saveFileDialog.ShowDialog() -eq 'OK') {
            try {
                reg export $($regPath -replace 'HKCU:', 'HKEY_CURRENT_USER' -replace 'HKLM:', 'HKEY_LOCAL_MACHINE' -replace 'HKCR:', 'HKEY_CLASSES_ROOT' -replace 'HKU:', 'HKEY_USERS' -replace 'HKCC:', 'HKEY_CURRENT_CONFIG') $saveFileDialog.FileName /y
                [System.Windows.Forms.MessageBox]::Show("Бэкап создан: $($saveFileDialog.FileName)", "Успех")
            } catch {
                $textBoxRegResult.Text = "Ошибка бэкапа: $($_.Exception.Message)"
            }
        }
    }
})

$tabRegistry.Controls.AddRange(@($labelRegPath, $textBoxRegPath, $buttonRegRead, $buttonRegDelete, $textBoxRegResult, $buttonRegExport, $buttonRegBackup, $buttonRegQuickAccess))

$tabControl.Controls.AddRange(@($tabCleanup, $tabSystem, $tabProcesses, $tabNetwork, $tabServices, $tabRegistry))

$form.Controls.Add($tabControl)

$form.Topmost = $true
$buttonRefreshSys.PerformClick()
$buttonRefreshProc.PerformClick()
$buttonRefreshServices.PerformClick()
$form.ShowDialog()
