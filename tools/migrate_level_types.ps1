# Rewrites the item type prefix of every itemId in assets/levels/*.json so the
# saved boards use the emoji-pack item types declared in ThemeRoom.

$ErrorActionPreference = 'Stop'

$levels = 'd:\Playstore\shelfsortm_master\assets\levels'

$ranges = @(
    @{ From = 1;   To = 25;  Map = @{ mug = 'orangejuice'; cup = 'buddletea'; jar = 'coffee' } },
    @{ From = 26;  To = 50;  Map = @{ cupcake = 'pancakestack'; box = 'strawberrypudding'; macaron = 'chocobanana' } },
    @{ From = 51;  To = 75;  Map = @{ book = 'mcdouble'; candle = 'mcdonaldsfries'; globe = 'chickenmcnuggets' } },
    @{ From = 76;  To = 100; Map = @{ pot = 'apple'; can = 'happycutelemon'; seed = 'sparklingwatermelonslice' } },
    @{ From = 101; To = 125; Map = @{ teddy = 'razzberry'; block = 'pinapberry'; ball = 'gopokeball' } },
    @{ From = 126; To = 150; Map = @{ perfume = 'pika16'; lipstick = 'pika38'; cream = 'pika54' } },
    @{ From = 151; To = 175; Map = @{ controller = 'ragetiktok'; cartridge = 'eviltiktok'; headset = 'ttcry' } },
    @{ From = 176; To = 200; Map = @{ can = 'caffelatte'; sauce = 'cuteteacup'; snack = 'cocacola' } },
    @{ From = 201; To = 225; Map = @{ vase = 'japanesecrepe'; frame = 'semla'; candle = 'cinnamonroll' } },
    @{ From = 226; To = 250; Map = @{ ribbon = 'normalegg'; bag = 'legendaryegg'; ornament = 'luckyegg' } }
)

$changed = 0
$leftovers = @{}

foreach ($range in $ranges) {
    for ($i = $range.From; $i -le $range.To; $i++) {
        $path = Join-Path $levels ("level_{0:d3}.json" -f $i)
        if (-not (Test-Path $path)) { continue }

        $text = [System.IO.File]::ReadAllText($path)
        $original = $text

        foreach ($old in $range.Map.Keys) {
            $text = $text -replace "`"$old`_", "`"$($range.Map[$old])_"
        }

        if ($text -ne $original) {
            [System.IO.File]::WriteAllText($path, $text)
            $changed++
        }

        foreach ($m in [regex]::Matches($text, '"([a-z]+)_[a-z]+_\d+"')) {
            $type = $m.Groups[1].Value
            if ($range.Map.Values -notcontains $type) { $leftovers[$type] = $true }
        }
    }
}

"files changed : $changed"
if ($leftovers.Count -gt 0) {
    "unmapped types: $($leftovers.Keys -join ', ')"
} else {
    "unmapped types: none"
}
