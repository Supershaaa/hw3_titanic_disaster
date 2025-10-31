# src/r/Dockerfile
FROM r-base:4.3.2
WORKDIR /app

# Install required R packages first (cache-friendly)
COPY install_packages.R /app/install_packages.R
RUN Rscript /app/install_packages.R

# Copy the R app
COPY app.R /app/src/r/app.R

# Run
CMD ["Rscript", "/app/src/r/app.R"]