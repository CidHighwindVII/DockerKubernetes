param(
	[switch]$Verbose
)

if ($Verbose) { Write-Host 'Evaluating the host environment...' }
if ($IsLinux) {
	if ($Verbose) { Write-Host 'Running on Linux. Calling docker directly.' }
} else {
	if ($Verbose) { Write-Host 'Running on Windows.' }

	try {
		if ($Verbose) { Write-Host 'Evaluating availability of WSL: ' -NoNewline }
		wsl.exe --exec pwsh -Command 'exit !$IsLinux'
		if ($Verbose) { Write-Host 'found.' }
		if ($Verbose) { Write-Host 'Evaluating availability of PowerShell inside WSL: ' -NoNewline }
		if ($LASTEXITCODE -eq 0) {
			if ($Verbose) { Write-Host 'found.' }
			if ($Verbose) { Write-Host 'Evaluating availability of Docker inside WSL: ' -NoNewline }
			wsl.exe --exec docker info *> $null
			if ($LASTEXITCODE -eq 0) {
				if ($Verbose) { Write-Host 'found.' }
				if ($Verbose) { Write-Host 'Executing this script from inside WSL.' }
				wsl.exe --exec pwsh -File $(wsl.exe --exec wslpath -a $PSCommandPath) Verbose:$Verbose
				return;
			} else {
				if ($Verbose) { Write-Host 'not found. Please check https://docs.docker.com/engine/install/.' }
			}
		} else {
			if ($Verbose) { Write-Host 'PowerShell is not installed inside WSL. Please check https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux/.' }
		}
	} catch {
		if ($Verbose) { Write-Host "not found. $_" }
	}

	if ($Verbose) { Write-Host 'Proceeding with execution on Windows Docker Desktop mode.' }
}

if ($Verbose) { Write-Host 'Removing stack...' }
docker stack rm mesInfrastructure

if ($Verbose) { Write-Host 'Removing secrets...' }
docker secret rm kafkasslcapem
docker secret rm Kafkasslcertificatepem
docker secret rm Kafkasslkeypem
docker secret rm clickhousesslcapem
docker secret rm redissslcapem

sudo rm -R "/opt/mesInfrastructure"
