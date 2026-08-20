# ProstateCancerVteIncidenceApp

This docker image is designed for hosting on results.ohdsi.org or similar ShinyProxy based platforms. It contains results for the ProstateCancerVteIncidence study found in the [ProstateCancerVteIncidence](https://github.com/ohdsi-studies/ProstateCancerVteIncidence).

## Overview

This repository and the Docker container are designed to work with the OHDSI Shiny proxy. More details on how this works are described [in this repo](https://github.com/OHDSI/OhdsiPredictionTutorial). When the container for this repository is built, it is automatically uploaded to Docker Hub [here](https://hub.docker.com/r/ohdsi/semaglutidenaionestappprostatecancervteincidenceapp/tags). From there the [ShinyProxyDeploy](https://github.com/OHDSI/ShinyProxyDeploy/) repository is updated to note the new container in the [application.yml](https://github.com/OHDSI/ShinyProxyDeploy/blob/main/application.yml#L228-L238).

## Usage

This README assumes you are familiar with Docker concepts. An overview of Docker can be found [here](https://docs.docker.com/guides/docker-overview/). Additionally, it assumes you have a PostgreSQL Database with a schema that contains results generated from the OHDSI Example Study found in the [Strategus Study Repo Template](https://github.com/ohdsi-studies/StrategusStudyRepoTemplate).

Since this container is designed to work with the OHDSI Shiny Proxy Deploy, it will require some modficiations if you'd like to use it on your machine. Here are the steps if you'd like to try it out:

- Clone this repository
- Add a file called `.env` to the root of the project to hold sensitive information. Specifically, you'll want to add your [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) to the `.env` file so it looks like this: 

```bash
build_github_pat="ghp_<secret>"
```

- Edit `app.R` to include the details to connect to your database. Specifically this section:

```r
cli::cli_h1("Starting shiny server")
serverStr <- paste0(Sys.getenv("shinydbServer"), "/", Sys.getenv("shinydbDatabase"))
cli::cli_alert_info("Connecting to {serverStr}")
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = serverStr,
  port = Sys.getenv("shinydbPort"),
  user = "shinyproxy",
  password = Sys.getenv("shinydbPw")
)


cli::cli_h2("Loading schema")
ShinyAppBuilder::createShinyApp(
   config = shinyConfig,
   connectionDetails = connectionDetails,
   resultDatabaseSettings = createDefaultResultDatabaseSettings(schema = "ohdsiexamplestudy"),
   title = "OHDSI Example Study"
   description = "The OHDSI Example Study is designed to run across the OHDSI Evidence Network to provide a way to test Strategus and all HADES modules."
)
```

In the code above, you'll want to replace the `DatabaseConnector::createConnectionDetails` with the details to connect to your PostgreSQL database with the study results. Additionally, you'll want to change the `schema` parameter in: `resultDatabaseSettings = createDefaultResultDatabaseSettings(schema = "ohdsiexamplestudy")` to match the schema where you have the study results. 

- Once the changes above are complete, you can build the container by running:

`docker-compose build`

- Once the docker container is built, you can run it:

`docker-compose up`

The application will be available on http://localhost:3838