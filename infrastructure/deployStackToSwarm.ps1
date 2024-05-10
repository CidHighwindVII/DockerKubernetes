param(
	[switch]$Verbose = $false
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
				wsl.exe --exec pwsh -File $(wsl.exe --exec wslpath -a $PSCommandPath) -Verbose:$Verbose 
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

if ($Verbose) { Write-Host "`nStarting the deployment..." }

if ($Verbose) { Write-Host 'Initializing Docker Swarm' }
docker swarm init
if ($Verbose) { Write-Host 'Pulling images' }
docker compose --file "$PSScriptRoot/docker-compose.yaml" pull

if ($Verbose) { Write-Host 'Create necessary folders for Clickhouse volumes' }
sudo mkdir -p "/opt/mesInfrastructure/ClickHouseDataFolder"
sudo mkdir -p "/opt/mesInfrastructure/ClickHouseLogFolder"
sudo mkdir -p "/opt/mesInfrastructure/ClickHouseData"
sudo mkdir -p "/opt/mesInfrastructure/ClickHouseData/Configs"
sudo mkdir -p "/opt/mesInfrastructure/ClickHouseData/Certificates/Kafka"
sudo mkdir -p "/opt/mesInfrastructure/ClickHouseData/Certificates/Generic"

if ($Verbose) { Write-Host 'Create necessary folders for Kafka volumes' }
sudo mkdir -p "/opt/mesInfrastructure/KafkaDataFolder"
sudo mkdir -p "/opt/mesInfrastructure/KafkaDataFolder/Certificates"

if ($Verbose) { Write-Host 'Create necessary folders for Redis volumes' }
sudo mkdir -p "/opt/mesInfrastructure/Redis"
sudo mkdir -p "/opt/mesInfrastructure/Redis/Certificates"
sudo chmod 777 -R /opt/mesInfrastructure

if ($Verbose) { Write-Host 'Copy configs/certificates to Clickhouse folders' }
sudo cp Configs/Clickhouse/* /opt/mesInfrastructure/ClickHouseData/Configs
sudo cp Certificates/Kafka/* /opt/mesInfrastructure/ClickHouseData/Certificates/Kafka
sudo cp Certificates/Generic/* /opt/mesInfrastructure/ClickHouseData/Certificates/Generic

if ($Verbose) { Write-Host 'Copy configs/certificates to Kafka folders' }
sudo cp Certificates/Kafka/* /opt/mesInfrastructure/KafkaDataFolder/Certificates

if ($Verbose) { Write-Host 'Copy configs/certificates to Redis folders' }
sudo cp Configs/Redis/* /opt/mesInfrastructure/Redis/
sudo cp Certificates/Generic/* /opt/mesInfrastructure/Redis/Certificates/

if ($Verbose) { Write-Host 'Replace dockerfile variables' }	
$wslAddress = $(ifconfig eth0 | grep -o 'inet [0-9.]\+' | awk '{print $2}')
$originalDockerCompose = Get-Content -Raw -Path "docker-compose.yaml"
sed -i "s/\wslAddress/$wslAddress/g" docker-compose.yaml

if ($Verbose) { Write-Host 'Create Kafka secrets' }
docker secret create kafkasslcapem ./Certificates/Kafka/root.crt
docker secret create kafkasslcertificatepem ./Certificates/Kafka/client.crt
docker secret create kafkasslkeypem ./Certificates/Kafka/client.key
docker secret create clickhousesslcapem ./Certificates/Generic/root.crt
docker secret create redissslcapem ./Certificates/Generic/root.crt

if ($Verbose) { Write-Host 'Deploying the Stack' }
docker stack deploy --compose-file "$PSScriptRoot/docker-compose.yaml" mesInfrastructure --with-registry-auth

$originalDockerCompose | Set-Content -Path "docker-compose.yaml" -NoNewline

if ($Verbose) { Write-Host 'Deployment completed' }
