
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$form = [System.Windows.Forms.Form]::new()
$form.Text = 'Один за всех'
$form.Size = '500,200'
$form.StartPosition = 'CenterScreen'


$label = [System.Windows.Forms.Label]::new()
$label.Text = 'Введите путь к папке для очистки:'
$label.Location = '20,20'
$label.Size = '400,25'

$textBox = [System.Windows.Forms.TextBox]::new()
$textBox.Location = '20,50'
$textBox.Size = '350,25'

$button = [System.Windows.Forms.Button]::new()
$button.Text = 'Выполнить очистку'
$button.Location = '20,100'
$button.Size = '150,30'


$button.Add_Click({
    
    [System.Windows.Forms.MessageBox]::Show("Очистка папки $($textBox.Text) запущена!", "Успех")
})

$form.Controls.Add($label)
$form.Controls.Add($textBox)
$form.Controls.Add($button)

$form.Topmost = $true
$form.ShowDialog()
