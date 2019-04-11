FROM ubuntu:xenial

RUN echo "BUILD MODULE: ONNXImageClassifierService"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-dev \
        libcurl4-openssl-dev \
        libboost-python-dev \
        libgtk2.0-dev \
        libopenjp2-7-dev \
        libtiff5-dev \
        zlib1g-dev \
        libjpeg-dev \
        libatlas-base-dev

# Install Python packages
COPY /build/amd64-requirements.txt amd64-requirements.txt
RUN pip3 install --upgrade pip
RUN pip3 install -r amd64-requirements.txt

# Cleanup
RUN rm -rf /var/lib/apt/lists/* \
    && apt-get -y autoremove

ADD app /app

# Expose the port
EXPOSE 8088

# Set the working directory
WORKDIR /app

# Run the flask server for the endpoints
CMD ["python3","app.py"]