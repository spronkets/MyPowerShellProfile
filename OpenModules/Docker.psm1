$rootUser = 'dev'
$rootPassword = 'Password!2'

function Install-DockerLocalnet {
  & docker network create --subnet=172.18.0.0/16 localnet
}

function Install-DockerSqlServerDb {
  # default user: sa, cannot be overriden
  & docker run --name sqlserver --restart unless-stopped -it -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=$rootPassword" -e "MSSQL_PID=Express" --net localnet --ip 172.18.0.22 -p 1433:1433 -d mcr.microsoft.com/mssql/server:latest
}

function Install-DockerPostgresDb {
  # default user: postgres, overriden by $rootUser
  & docker run --name postgres --restart unless-stopped -it -e POSTGRES_USER=$rootUser -e POSTGRES_PASSWORD=$rootPassword --net localnet --ip 172.18.0.24 -p 5432:5432 -d postgres:latest
}

function Install-DockerMysqlDb {
  # default user: root, cannot be overriden
  & docker run --name mysql --restart unless-stopped -it -e MYSQL_ROOT_PASSWORD=$rootPassword --net localnet --ip 172.18.0.23 -p 3306:3306 -d mysql:latest
}

function Install-DockerMongoDb {
  # no default user, set by $rootUser
  & docker run --name mongo --restart unless-stopped -it -e MONGO_INITDB_ROOT_USERNAME=$rootUser -e MONGO_INITDB_ROOT_PASSWORD=$rootPassword --net localnet --ip 172.18.0.25 -p 27017:27017 -d mongo:latest
}
