# 1. Загружаем библиотеки (обязательный ритуал)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 2. Создаем само окно
$form = [System.Windows.Forms.Form]::new()
$form.Text = 'Мой Швейцарский Нож'
$form.Size = '500,200'
$form.StartPosition = 'CenterScreen'

# 3. Создаем надпись (Label)
$label = [System.Windows.Forms.Label]::new()
$label.Text = 'Введите путь к папке для очистки:'
$label.Location = '20,20'
$label.Size = '400,25'

# 4. Создаем поле ввода (TextBox)
$textBox = [System.Windows.Forms.TextBox]::new()
$textBox.Location = '20,50'
$textBox.Size = '350,25'

# 5. Создаем кнопку (Button)
$button = [System.Windows.Forms.Button]::new()
$button.Text = 'Выполнить очистку'
$button.Location = '20,100'
$button.Size = '150,30'

# --- Магия PowerShell: Вешаем действие на кнопку ---
$button.Add_Click({
    # Тут будет ваш код по очистке системы
    # Например: Remove-Item -Path $textBox.Text -Recurse -Force
    [System.Windows.Forms.MessageBox]::Show("Очистка папки $($textBox.Text) запущена!", "Успех")
})

# 6. Собираем все элементы в окно
$form.Controls.Add($label)
$form.Controls.Add($textBox)
$form.Controls.Add($button)

# 7. Показываем окно поверх всех и ждем действий
$form.Topmost = $true
$form.ShowDialog()