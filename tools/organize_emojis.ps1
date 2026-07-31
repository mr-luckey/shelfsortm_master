# Extracts the emoji.gg packs from Downloads into assets/images/emojis/<category>/
# Names are cleaned (numeric id prefix stripped). Identical duplicates are skipped;
# different files that clean to the same name get a _2, _3 ... suffix so nothing is lost.

$ErrorActionPreference = 'Stop'

$downloads = 'C:\Users\engin\Downloads'
$repo = 'd:\Playstore\shelfsortm_master'
$work = Join-Path $env:TEMP 'emojipacks_work'
$dest = Join-Path $repo 'assets\images\emojis'

$packCategory = @{
    '40333-drinks-emojigg-pack'                  = 'drinks'
    '2261-drijuice-food-pack-emojigg-pack'       = 'bakery'
    '6440-mcdonald-emoji-pack-fixed-emojigg-pack'= 'fastfood'
    '23707-poke-fruits-emojigg-pack'             = 'poke'
    '567278-pikachu-1-emojigg-pack'              = 'pikachu'
    '695155-pikachu-2-emojigg-pack'              = 'pikachu'
    '217559-pikachu-3-emojigg-pack'              = 'pikachu'
    '210474-pikachu-4-emojigg-pack'              = 'pikachu'
    '178344-tiktok-cute-emojis-emojigg-pack'     = 'tiktok'
    '526262-tiktok-emojis-emojigg-pack'          = 'tiktok'
    '20050-foodanddrink-emojigg-pack'            = 'food'
}

# The food & drink pack mixes both kinds; these go to drinks, the rest to food.
$drinkOverrides = @('cute_teacup', 'cocoa', 'buddle_tea', 'champagne_glasses')

function Get-CleanName([string]$fileName) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $base = $base -replace '^\d+[-_]', ''
    $base = $base.ToLowerInvariant() -replace '[^a-z0-9]+', '_'
    return $base.Trim('_')
}

if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $work | Out-Null

foreach ($zip in [System.IO.Directory]::GetFiles($downloads, '*emojigg-pack.zip')) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($zip)
    Expand-Archive -Path $zip -DestinationPath (Join-Path $work $name) -Force
}

$hashes = @{}
$copied = 0
$skipped = 0
$renamed = 0

foreach ($src in [System.IO.Directory]::GetFiles($work, '*.*', [System.IO.SearchOption]::AllDirectories)) {
    $pack = Split-Path (Split-Path $src -Parent) -Leaf
    $category = $packCategory[$pack]
    if (-not $category) { continue }

    $clean = Get-CleanName ([System.IO.Path]::GetFileName($src))
    if ($category -eq 'food' -and $drinkOverrides -contains $clean) { $category = 'drinks' }

    $ext = [System.IO.Path]::GetExtension($src).ToLowerInvariant()
    $dir = Join-Path $dest $category
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $hash = (Get-FileHash $src -Algorithm SHA256).Hash
    $target = Join-Path $dir "$clean$ext"
    $suffix = 1
    while (Test-Path $target) {
        if ($hashes[$target] -eq $hash) { break }
        $suffix++
        $target = Join-Path $dir "${clean}_$suffix$ext"
    }

    if ((Test-Path $target) -and $hashes[$target] -eq $hash) {
        $skipped++
        continue
    }
    if ($suffix -gt 1) { $renamed++ }

    Copy-Item $src $target -Force
    $hashes[$target] = $hash
    $copied++
}

Remove-Item $work -Recurse -Force

"copied  : $copied"
"skipped : $skipped (identical duplicates)"
"renamed : $renamed (name clash, kept both)"
foreach ($dir in [System.IO.Directory]::GetDirectories($dest)) {
    "{0,-10} {1}" -f (Split-Path $dir -Leaf), [System.IO.Directory]::GetFiles($dir).Count
}
