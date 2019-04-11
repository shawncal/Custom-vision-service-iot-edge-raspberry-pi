FROM balenalib/raspberrypi3
# The balena base image for building apps on Raspberry Pi 3.

RUN echo "BUILD MODULE: ONNXImageClassifierService"

#Enforces cross-compilation through Quemu
RUN [ "cross-build-start" ]

RUN install_packages \
    sudo \
    build-essential \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    wget \
    python3 \
    python3-pip \
    python3-dev \
    git \
    tar

RUN pip3 install --upgrade pip
RUN pip3 install --upgrade setuptools
RUN pip3 install --index-url=https://www.piwheels.org/simple \
    cmake \
    numpy \
    wheel

# Set up build args
ARG BUILDTYPE=Release
ARG BUILDARGS="--config ${BUILDTYPE} --arm"

# Prepare onnxruntime Repo
WORKDIR /code
RUN git clone --recursive https://github.com/Microsoft/onnxruntime

# Temporary fix - Remove a line causing build break
WORKDIR /code/onnxruntime/tools/ci_build
RUN grep -v "onnxruntime_DEV_MODE" build.py > build.py.temp
RUN mv build.py.temp build.py

# Start the basic build
WORKDIR /code/onnxruntime
RUN ./build.sh ${BUILDARGS} --update --build

# Build Shared Library
RUN ./build.sh ${BUILDARGS} --build_shared_lib

# TODO: Move to top
RUN install_packages libatlas-base-dev

# Build Python Bindings and Wheel
RUN ./build.sh ${BUILDARGS} --enable_pybind --build_wheel

# Install onnxruntime wheel
RUN pip3 install --upgrade /code/onnxruntime/build/Linux/${BUILDTYPE}/dist/*.whl

# Install additional packages required at runtime
COPY /build/arm32v7-requirements.txt ./
RUN pip3 install --index-url=https://www.piwheels.org/simple -r arm32v7-requirements.txt

RUN install_packages \
    libopenjp2-7-dev \
    libtiff5-dev \
    zlib1g-dev \
    libjpeg-dev \
    libatlas-base-dev

RUN [ "cross-build-end" ]

# Add the application
ADD app /app

# Expose the port
EXPOSE 8088

# Set the working directory
WORKDIR /app

# Run the flask server for the endpoints
CMD ["python3","app.py"]