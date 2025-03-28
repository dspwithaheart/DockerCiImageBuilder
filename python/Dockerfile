FROM python:3.13.0 as base
# Dockerfile for Kaniko
#!! Kaniko runs Dockerfile from Project Root so paths are relative
#   to project root not from where Dockerfile ist located
ENV PYTHONUNBUFFERED=1 \
    DIR_LOG=/log \
    STATIC_ROOT=/static \
    DEBIAN_FRONTEND=noninteractive
# install packages
RUN apt-get update && \
        apt-get -y install gcc g++ libaio1 alien wget python3-dev default-libmysqlclient-dev build-essential libsasl2-dev python-dev-is-python3 libldap2-dev libssl-dev && \
    wget -q https://download.oracle.com/otn_software/linux/instantclient/2340000/oracle-instantclient-basic-23.4.0.24.05-1.el8.x86_64.rpm && \
    alien -i oracle-instantclient-basic-23.4.0.24.05-1.el8.x86_64.rpm && \
    rm oracle-instantclient-basic-23.4.0.24.05-1.el8.x86_64.rpm && \
    echo /usr/lib/oracle/23/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
