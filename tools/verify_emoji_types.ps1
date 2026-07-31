# Checks that every emoji type referenced from Dart or from a level JSON has
# artwork in EmojiAssets, and that every mapped file is on disk.

$ErrorActionPreference = 'Stop'

$repo = 'd:\Playstore\shelfsortm_master'
Set-Location $repo

$map = @{}
foreach ($line in [System.IO.File]::ReadAllLines('lib\ui\widgets\emoji_assets.dart')) {
    if ($line -match "^\s+'([^']+)': '([^']+)',$") { $map[$Matches[1]] = $Matches[2] }
}
"map entries        : $($map.Count)"

$missingFiles = $map.Keys | Where-Object { -not (Test-Path $map[$_]) }
"assets on disk     : $(if ($missingFiles) { "MISSING $($missingFiles -join ', ')" } else { 'all present' })"

$referenced = @{}

# ThemeRoom item types + room icons
$themeText = [System.IO.File]::ReadAllText('lib\models\theme_room.dart')
foreach ($block in [regex]::Matches($themeText, 'itemTypes:\s*\[(.*?)\]', 'Singleline')) {
    foreach ($m in [regex]::Matches($block.Groups[1].Value, "'([^']+)'")) {
        $referenced[$m.Groups[1].Value] = 'theme_room itemTypes'
    }
}
foreach ($m in [regex]::Matches($themeText, "iconType:\s*'([^']+)'")) {
    $referenced[$m.Groups[1].Value] = 'theme_room iconType'
}

# EmojiImage(type: '...') literals anywhere in lib/
foreach ($f in [System.IO.Directory]::GetFiles('lib', '*.dart', [System.IO.SearchOption]::AllDirectories)) {
    $text = [System.IO.File]::ReadAllText($f)
    foreach ($m in [regex]::Matches($text, "EmojiImage\(\s*type:\s*'([^']+)'")) {
        $referenced[$m.Groups[1].Value] = $f
    }
}

# Item types baked into the saved level boards
foreach ($f in [System.IO.Directory]::GetFiles('assets\levels', '*.json')) {
    foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($f), '"itemId":\s*"([^_"]+)_')) {
        $referenced[$m.Groups[1].Value] = 'level json'
    }
}

"types referenced   : $($referenced.Count)"
$unmapped = $referenced.Keys | Where-Object { -not $map.ContainsKey($_) } | Sort-Object
if ($unmapped) {
    foreach ($u in $unmapped) { "  UNMAPPED $u  (from $($referenced[$u]))" }
    exit 1
}
"all types resolved : yes"
