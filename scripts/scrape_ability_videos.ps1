# Rebuilds assets/data/ability_videos.json: maps each agent (by valorant-api.com
# uuid) to its ability names and the mp4 preview clip URL scraped from the
# corresponding official playvalorant.com/fr-fr agent page. Run from anywhere;
# run periodically since Riot can change the page markup or reshuffle assets.
$ErrorActionPreference = 'Stop'

function Get-Slug($name) {
    $s = $name.ToLower().Replace('/', '-')
    return ($s -replace '[^a-z0-9-]', '')
}

$agentsResp = Invoke-RestMethod -Uri "https://valorant-api.com/v1/agents?isPlayableCharacter=true&language=fr-FR"
$agents = $agentsResp.data

$result = @{}
$total = $agents.Count
$i = 0

foreach ($agent in $agents) {
    $i++
    $slug = Get-Slug $agent.displayName
    $url = "https://playvalorant.com/fr-fr/agents/$slug/"
    Write-Host "[$i/$total] $($agent.displayName) -> $url"

    try {
        $html = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
        $content = $html.Content
        $pattern = '"sources":\[\{"src":"([^"]+\.mp4[^"]*)"[^}]*\}\]\},"title":"([^"]+)"'
        $matches = [regex]::Matches($content, $pattern)

        $abilityMap = @{}
        foreach ($m in $matches) {
            $mp4 = $m.Groups[1].Value -replace '\\u002F', '/'
            $title = $m.Groups[2].Value.Trim().ToUpper()
            if (-not $abilityMap.ContainsKey($title)) {
                $abilityMap[$title] = $mp4
            }
        }

        $result[$agent.uuid] = $abilityMap
        Write-Host "  found $($abilityMap.Count) videos"
    } catch {
        Write-Host "  FAILED: $($_.Exception.Message)"
        $result[$agent.uuid] = @{}
    }

    Start-Sleep -Milliseconds 200
}

$outputPath = Join-Path $PSScriptRoot "..\assets\data\ability_videos.json"
$result | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding utf8
Write-Host "Done. Wrote $outputPath"
