# Удалить, если существует (без вывода)
if (Test-Path ".\frontend\node_modules") { Remove-Item ".\frontend\node_modules" -Recurse -Force }

# Удалить без проверки (тихо)
Remove-Item ".\frontend\node_modules" -Recurse -Force -ErrorAction SilentlyContinue

# Удалить с подтверждением
if (Test-Path ".\frontend") { Remove-Item ".\frontend" -Recurse -Confirm }

# Удалить несколько папок одной командой
@(".\frontend\dist", ".\functions\lib") | Where-Object { Test-Path $_ } | Remove-Item -Recurse -Force