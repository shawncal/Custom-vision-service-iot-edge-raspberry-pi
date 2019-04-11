FROM ubuntu:xenial

RUN echo "BUILD MODULE: ONNXImageClassifierService"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        python3-pip \
        libboost-python-dev \
        libgtk2.0-dev \
        libopenjp2-7-dev \
        libtiff5-dev \
        zlib1g-dev \
        libjpeg-dev \
        libatlas-base-dev

# Install Python packages
COPY /build/amd64-requirements.txt amd64-requirements.txt
RUN sudo pip3 install --upgrade pip
RUN pip install -r amd64-requirements.txt

ADD app /app

# Expose the port
EXPOSE 8088

# Set the working directory
WORKDIR /app

# Run the flask server for the endpoints
CMD ["python3","app.py"]