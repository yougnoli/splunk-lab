# ------------------------------------------------------------
# Stage 1: obtain Java 17
# ------------------------------------------------------------
FROM eclipse-temurin:17-jre AS java-runtime

# ------------------------------------------------------------
# Stage 2: create the final Splunk Enterprise image
# ------------------------------------------------------------
FROM splunk/splunk:latest

USER root

# Copy Java 17 from the first image into the Splunk image.
# This avoids depending on apt, yum, dnf, or microdnf.
COPY --from=java-runtime /opt/java/openjdk /opt/java/openjdk

# Tell DB Connect and other applications where Java is installed.
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Return to the standard user used by the Splunk container startup.
USER ansible