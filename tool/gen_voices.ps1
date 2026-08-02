Add-Type -AssemblyName System.Speech
$syn = New-Object System.Speech.Synthesis.SpeechSynthesizer
$syn.Rate = 1
$syn.Volume = 90
$outDir = "assets/audio"
$map = @{
  "voice_nice.wav" = "Nice!"
  "voice_great.wav" = "Great!"
  "voice_awesome.wav" = "Awesome!"
  "voice_perfect.wav" = "Perfect!"
  "voice_amazing.wav" = "Amazing!"
}
foreach ($name in $map.Keys) {
  $path = Join-Path $outDir $name
  $syn.SetOutputToWaveFile((Resolve-Path .).Path + "\" + $path)
  $syn.Speak($map[$name])
  $syn.SetOutputToNull()
  Write-Host "wrote $path"
}
$syn.Dispose()
