param(
    [Parameter(Mandatory)]
    [string]$TemplateRoot,

    [Parameter(Mandatory)]
    [string]$TargetRoot,

    [Parameter(Mandatory)]
    [string]$Namespace
)
$templatesFullPath = (Resolve-Path $TemplateRoot).Path

Get-ChildItem $TemplateRoot -Recurse  -File |
    Where-Object {
        $_.Name -like '*.tsx.tpl' -or
        $_.Name -like '*.ts.tpl' -or
		$_.Name -like '*.html.tpl' -or
		$_.Name -like '*.css.tpl' -or
        $_.Name -like '*.json.tpl' -or
		$_.Name -like '*.env'-or
		$_.Name -like '*.local.tpl'	
    } | ForEach-Object {
    # относительный путь
    $relativePath = $_.FullName.Substring($templatesFullPath.Length)

    $targetPath   = Join-Path $TargetRoot $relativePath.Replace(".tpl","")
    $targetDir = Split-Path $targetPath

    # папка назначения
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    
    # обработка шаблона
    $content = Get-Content $_.FullName -Raw
	
	$replacements = @{
    Namespace = $Namespace
    Layer     = "Controllers"
    ClassName = "UserController"
}

foreach ($key in $replacements.Keys) {
    $content = $content -replace "\{\{$key\}\}", $replacements[$key]
}
    Set-Content -Path $targetPath -Value $content #-Encoding UTF8	
   
}


   