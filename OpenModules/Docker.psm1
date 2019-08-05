function Install-DockerLocalnet {
  & docker network create --subnet=172.18.0.0/16 localnet
}

function Install-DockerSqlServerDb {
  & docker run --name sqlserver --restart always -it -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Password!2" --net localnet --ip 172.18.0.22 -p 1433:1433 -d microsoft/mssql-server-linux:2017-latest
}

function Install-DockerPostgresDb {
  # note: doesn't currently use localnet
  & docker run --name postgres --restart always -it -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -p 5432:5432 -d postgres
}

function Invoke-DockerCompose {
  & docker build
  & docker-compose up -d
}