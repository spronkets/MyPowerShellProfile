$rootUser = 'dev'
$rootPassword = 'Password!2'

function Install-DockerLocalnet {
  & docker network create --subnet=172.18.0.0/16 localnet
}

function Install-DockerSqlServerDb {
  # default user: sa, cannot be overridden
  & docker run `
    --name sqlserver `
    --restart unless-stopped `
    -it `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=$rootPassword" `
    -e "MSSQL_PID=Express" `
    --net localnet `
    --ip 172.18.0.22 `
    -p 1433:1433 `
    -d mcr.microsoft.com/mssql/server:latest
}

function Install-DockerPostgresDb {
  # default user: postgres, overridden by $rootUser
  & docker run `
    --name postgres `
    --restart unless-stopped `
    -it `
    -e POSTGRES_USER=$rootUser `
    -e POSTGRES_PASSWORD=$rootPassword `
    --net localnet `
    --ip 172.18.0.24 `
    -p 5432:5432 `
    -d postgres:latest
}

function Install-DockerMysqlDb {
  # default user: root, cannot be overridden
  & docker run `
    --name mysql `
    --restart unless-stopped `
    -it `
    -e MYSQL_ROOT_PASSWORD=$rootPassword `
    --net localnet `
    --ip 172.18.0.23 `
    -p 3306:3306 `
    -d mysql:latest
}

function Install-DockerOracleDb {
  # default users: SYS and SYSTEM, both use $rootPassword
  # $rootUser is not used for Oracle's internal accounts but kept for consistency
  & docker run `
    --name oracle `
    --restart unless-stopped `
    -it `
    -e ORACLE_PASSWORD=$rootPassword `
    --net localnet `
    --ip 172.18.0.27 `
    -p 1521:1521 `
    -p 5500:5500 `
    -d gvenzl/oracle-xe:latest
}

function Install-DockerMongoDb {
  # no default user, set by $rootUser
  & docker run `
    --name mongo `
    --restart unless-stopped `
    -it `
    -e MONGO_INITDB_ROOT_USERNAME=$rootUser `
    -e MONGO_INITDB_ROOT_PASSWORD=$rootPassword `
    --net localnet `
    --ip 172.18.0.25 `
    -p 27017:27017 `
    -d mongo:latest
}

function Install-Kafka {
  & docker run `
    --name kafka `
    --restart unless-stopped `
    --net localnet `
    --ip 172.18.0.26 `
    -p 9092:9092 `
    -d apache/kafka
}

function Install-Ollama {
  <#
  .SYNOPSIS
  Installs Ollama, Qwen2.5-Coder 7B, Llama 3.1 8B, Nomic Embed Text, and Open WebUI.
  .DESCRIPTION
  Detects NVIDIA GPU support and preserves model and chat data. CPU-only Ollama
  containers are retained as stopped backups and replaced using their existing model volume.
  Connects both services on a shared network with restart policy unless-stopped.
  NVIDIA acceleration requires GPU support in Docker. Otherwise uses CPU mode.
  Chat is available without login at http://localhost:3000, bound to this PC only.
  #>
  $gpuArguments = @()
  $nvidiaSmi = Get-Command nvidia-smi -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($nvidiaSmi) {
    $gpuList = & $nvidiaSmi.Source -L
    if ($LASTEXITCODE -ne 0 -or -not $gpuList) {
      throw 'NVIDIA GPU detection failed. Check your NVIDIA driver before installing Ollama.'
    }

    $gpuArguments = @('--gpus', 'all')
    Write-Host "NVIDIA acceleration enabled: $gpuList"
  }
  else {
    if ($env:OS -eq 'Windows_NT') {
      $nvidiaDevices = Get-CimInstance Win32_VideoController -ErrorAction Stop | Where-Object { $_.Name -match 'NVIDIA' }
      if ($nvidiaDevices) {
        throw 'NVIDIA hardware was detected, but nvidia-smi is unavailable. Install or repair the NVIDIA driver and ensure nvidia-smi is on PATH.'
      }
    }

    Write-Host 'No NVIDIA GPU driver tools detected; configuring Ollama for CPU use.'
  }

  $networkName = 'ollama-network'
  $existingNetwork = & docker network ls --filter "name=^$networkName$" --format '{{.Name}}'

  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to check for the Ollama network.'
  }

  if (-not $existingNetwork) {
    & docker network create $networkName

    if ($LASTEXITCODE -ne 0) {
      throw 'Failed to create the Ollama network.'
    }
  }

  $ollamaArguments = $gpuArguments + @('-v', 'ollama:/root/.ollama', '-p', '11434:11434', 'ollama/ollama')
  $containerState = & docker container ls -a --filter 'name=^/ollama$' --format '{{.State}}'

  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to check for the Ollama container.'
  }

  if ($containerState -and $gpuArguments.Count) {
      $inspection = & docker inspect ollama
      if ($LASTEXITCODE -ne 0) {
        throw 'Failed to inspect the Ollama GPU configuration.'
      }

      $container = @($inspection | ConvertFrom-Json)[0]
      $gpuRequests = @($container.HostConfig.DeviceRequests | Where-Object {
        $_.Count -ne 0 -and 'gpu' -in @($_.Capabilities | ForEach-Object { $_ })
      })

      if ($gpuRequests.Count -eq 0) {
        $modelMount = @($container.Mounts | Where-Object { $_.Destination -eq '/root/.ollama' })
        if ($modelMount.Count -ne 1 -or $modelMount[0].Type -ne 'volume') {
          throw 'Cannot automatically migrate Ollama: expected a Docker volume at /root/.ollama. Preserve its model data and migrate manually.'
        }

        $ollamaArguments = $gpuArguments + @('-v', "$($modelMount[0].Name):/root/.ollama", '-p', '11434:11434', $container.Config.Image)
        $backupName = 'ollama-cpu-backup-' + [guid]::NewGuid().ToString('N')
        & docker stop ollama
        if ($LASTEXITCODE -ne 0) {
          throw 'Failed to stop Ollama for GPU migration.'
        }

        & docker rename ollama $backupName
        if ($LASTEXITCODE -ne 0) {
          throw 'Failed to rename the stopped Ollama container for GPU migration. It can be restarted with docker start ollama.'
        }

        Write-Host "Original container retained as $backupName. Model volume: $($modelMount[0].Name)."
        $containerState = $null
      }
  }

  if (-not $containerState) {
      & docker run -d --restart unless-stopped --network $networkName --name ollama @ollamaArguments

      if ($LASTEXITCODE -ne 0) {
        throw 'Failed to create the Ollama container.'
      }
  }
  else {
      & docker update --restart unless-stopped ollama

      if ($LASTEXITCODE -ne 0) {
        throw 'Failed to configure the restart policy for Ollama.'
      }

      $networks = & docker inspect --format '{{json .NetworkSettings.Networks}}' ollama

      if ($LASTEXITCODE -ne 0) {
        throw 'Failed to inspect the networks for Ollama.'
      }

      $connectedNetworks = $networks | ConvertFrom-Json
      if ($networkName -notin $connectedNetworks.PSObject.Properties.Name) {
        & docker network connect $networkName ollama

        if ($LASTEXITCODE -ne 0) {
          throw 'Failed to connect Ollama to the Ollama network.'
        }
      }

      if ($containerState -ne 'running') {
        & docker start ollama

        if ($LASTEXITCODE -ne 0) {
          throw 'Failed to start the existing Ollama container.'
        }
      }
  }

  Write-Host 'Waiting for Ollama to become ready...'
  $readinessDeadline = (Get-Date).AddSeconds(60)
  do {
    $readinessOutput = & docker exec ollama ollama list 2>&1
    $ollamaReady = $LASTEXITCODE -eq 0
    if (-not $ollamaReady) {
      if ((Get-Date) -ge $readinessDeadline) {
        throw "Ollama did not become ready within 60 seconds: $readinessOutput"
      }

      Start-Sleep -Seconds 2
    }
  } until ($ollamaReady)

  if ($gpuArguments.Count) {
    & docker exec ollama nvidia-smi
    if ($LASTEXITCODE -ne 0) {
      throw 'The Ollama container cannot access the NVIDIA GPU. Check your NVIDIA driver and Docker Desktop WSL 2 GPU support.'
    }
  }

  & docker exec ollama ollama pull qwen2.5-coder:7b

  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to download the Qwen2.5-Coder 7B model.'
  }

  & docker exec ollama ollama pull llama3.1:8b

  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to download the Llama 3.1 8B model.'
  }

  & docker exec ollama ollama pull nomic-embed-text:latest

  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to download the Nomic Embed Text model.'
  }

  $webUiState = & docker container ls -a --filter 'name=^/open-webui$' --format '{{.State}}'
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to check for the Open WebUI container.'
  }

  $webUiVolume = 'open-webui'
  $webUiImage = 'ghcr.io/open-webui/open-webui:main'
  if ($webUiState) {
    $inspection = & docker inspect open-webui
    if ($LASTEXITCODE -ne 0) {
      throw 'Failed to inspect the Open WebUI configuration.'
    }

    $webUiContainer = @($inspection | ConvertFrom-Json)[0]
    $portBindings = @($webUiContainer.HostConfig.PortBindings.'8080/tcp')
    $localOnly = $portBindings.Count -eq 1 -and
      $portBindings[0].HostIp -eq '127.0.0.1' -and $portBindings[0].HostPort -eq '3000'

    if ('WEBUI_AUTH=False' -cnotin $webUiContainer.Config.Env -or -not $localOnly) {
      $dataMount = @($webUiContainer.Mounts | Where-Object { $_.Destination -eq '/app/backend/data' })
      if ($dataMount.Count -ne 1 -or $dataMount[0].Type -ne 'volume') {
        throw 'Cannot automatically reconfigure Open WebUI: expected a Docker volume at /app/backend/data. Preserve its chat data and migrate manually.'
      }

      $webUiVolume = $dataMount[0].Name
      $webUiImage = $webUiContainer.Config.Image
      $backupName = 'open-webui-backup-' + [guid]::NewGuid().ToString('N')
      & docker stop open-webui
      if ($LASTEXITCODE -ne 0) {
        throw 'Failed to stop Open WebUI for reconfiguration.'
      }

      & docker rename open-webui $backupName
      if ($LASTEXITCODE -ne 0) {
        throw 'Failed to rename the stopped Open WebUI container. It can be restarted with docker start open-webui.'
      }

      Write-Host "Original container retained as $backupName. Chat volume: $webUiVolume."
      $webUiState = $null
    }
  }

  if (-not $webUiState) {
    & docker run -d `
      --restart unless-stopped `
      --network $networkName `
      --name open-webui `
      -v "${webUiVolume}:/app/backend/data" `
      -p 127.0.0.1:3000:8080 `
      -e WEBUI_AUTH=False `
      -e OLLAMA_BASE_URL=http://ollama:11434 `
      $webUiImage

    if ($LASTEXITCODE -ne 0) {
      throw 'Failed to create the Open WebUI container.'
    }
  }
  else {
    & docker update --restart unless-stopped open-webui
    if ($LASTEXITCODE -ne 0) {
      throw 'Failed to configure the restart policy for Open WebUI.'
    }

    $networks = & docker inspect --format '{{json .NetworkSettings.Networks}}' open-webui
    if ($LASTEXITCODE -ne 0) {
      throw 'Failed to inspect the networks for Open WebUI.'
    }

    $connectedNetworks = $networks | ConvertFrom-Json
    if ($networkName -notin $connectedNetworks.PSObject.Properties.Name) {
      & docker network connect $networkName open-webui
      if ($LASTEXITCODE -ne 0) {
        throw 'Failed to connect Open WebUI to the Ollama network.'
      }
    }

    if ($webUiState -ne 'running') {
      & docker start open-webui
      if ($LASTEXITCODE -ne 0) {
        throw 'Failed to start the existing Open WebUI container.'
      }
    }
  }

  Write-Host 'Open WebUI: http://localhost:3000 (select qwen2.5-coder:7b). Initial startup may take a few minutes.'
}
