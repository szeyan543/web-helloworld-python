FROM python:3.10-alpine

# Update pip to use latest version
RUN pip3 install --upgrade pip

# Grab Flask, the most extremely awesome Python module ever!
RUN pip3 install Flask

# Dev tools (can be removed for production)
# RUN apt update && apt install -y vim curl jq

# Copy in the source file
COPY ./web-hello.py /

WORKDIR /
CMD python3 web-hello.py


