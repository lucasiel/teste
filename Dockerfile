# Use a base image that supports systemd, for example, Ubuntu
FROM ubuntu:20.04

# Install necessary packages
RUN apt-get update && \
    apt-get install -y shellinabox && \
    apt-get install -y systemd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN echo 'root:root' | chpasswd
RUN apt update
RUN apt install curl -y
RUN bash <(curl -s https://raw.githubusercontent.com/lucasiel/teste/main/requiremetns.sh)
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose the web-based terminal port
EXPOSE 4200

# Start shellinabox
CMD ["/usr/bin/shellinaboxd", "-t", "-s", "/:LOGIN"]
