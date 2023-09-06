crystal build src\main.cr -o crimson.exe
Get-FileHash crimson.exe | Select-Object Hash | Format-Table -HideTableHeaders | Out-File checksums.txt
$compress = @{
    Path = "crimson.exe", "crimson.pdb", "checksums.txt"
    DestinationPath = "crimson-nightly-windows-x86_64-msvc.zip"
}
Compress-Archive @compress

# gh release delete nightly -y
gh release create nightly -dpt nightly
gh release upload nightly crimson-nightly-windows-x86_64-msvc.zip

Remove-Item -ErrorAction SilentlyContinue -Force .\crimson.exe .\crimson.pdb .\checksums.txt .\crimson-nightly-windows-x86_64-msvc.zip
