# get shiny server and R from the rocker project
FROM ohdsi/broadsea-shiny:1.0.0

# JNJ Specific 
#RUN apt-get install -y ca-certificates
#COPY ZscalerRootCA.crt /root/ZscalerRootCA.crt
#RUN cat /root/ZscalerRootCA.crt >> /etc/ssl/certs/ca-certificates.crt
#COPY ZscalerRootCA.crt /usr/local/share/ca-certificates
#RUN update-ca-certificates

# Set an argument for the app name and port
ARG APP_NAME
ARG SHINY_PORT

# Set arguments for the GitHub branch and commit id abbreviation
ARG GIT_BRANCH=unknown
ARG GIT_COMMIT_ID_ABBREV=unknown

# system libraries
# Try to only install system libraries you actually need
# Package Manager is a good resource to help discover system deps
RUN apt-get update && \
    apt-get install -y \
        python3-pip \
        libuv1-dev \
        libv8-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Use Ubuntu's shared libnode instead of downloading static V8.
# The V8 package's default /usr/include/v8 header path is correct.
ENV V8_PKG_CFLAGS="-I/usr/include/nodejs/deps/v8/include"
ENV V8_PKG_LIBS="-lnode"

RUN R -e ' \
  install.packages("remotes", repos = "https://cloud.r-project.org/"); \
  remotes::install_version( \
    "V8", \
    version = "4.4.2", \
    repos = "https://cloud.r-project.org/", \
    upgrade = "never" \
  ); \
  packages <- c( \
    "rJava", "dplyr", "DatabaseConnector", \
    "ggplot2", "plotly", "shinyWidgets", "shiny", \
    "forestploter", "gt", "gtExtras" \
  ); \
  install.packages(packages, repos = "https://cloud.r-project.org/"); \
  required <- c("remotes", "V8", packages); \
  missing <- required[!vapply( \
    required, requireNamespace, logical(1), quietly = TRUE \
  )]; \
  if (length(missing)) { \
    stop(paste("Packages failed to load:", paste(missing, collapse = ", "))) \
  }'

RUN R CMD javareconf

# Set workdir and copy app files
WORKDIR /srv/shiny-server/${APP_NAME}

# copy the app directory into the image
COPY ./app.R .

# install additional R packages and fail the build if there are any missing dependencies
RUN --mount=type=secret,id=build_github_pat \
    cp /usr/local/lib/R/etc/Renviron /tmp/Renviron && \
    echo "GITHUB_PAT=$(cat /run/secrets/build_github_pat)" >> /usr/local/lib/R/etc/Renviron && \
    R -e "remotes::install_github('OHDSI/ResultModelManager'); if (!require('ResultModelManager', quietly = TRUE)) stop('Installation of ResultModelManager failed')" && \
    R -e "remotes::install_github('OHDSI/ShinyAppBuilder'); if (!require('ShinyAppBuilder', quietly = TRUE)) stop('Installation of ShinyAppBuilder failed')" && \
    R -e "remotes::install_github('OHDSI/OhdsiShinyModules'); if (!require('OhdsiShinyModules', quietly = TRUE)) stop('Installation of OhdsiShinyModules failed')" && \
    cp /tmp/Renviron /usr/local/lib/R/etc/Renviron

ENV DATABASECONNECTOR_JAR_FOLDER=/root
RUN R -e "DatabaseConnector::downloadJdbcDrivers('postgresql', pathToDriver='/root')"

# run app
EXPOSE 3838
CMD R -e "shiny::runApp('./', host = '0.0.0.0', port = 3838)"
