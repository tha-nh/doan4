#!/bin/bash

# Cài đặt Maven
curl -O https://downloads.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
tar xzvf apache-maven-3.9.9-bin.tar.gz
export M2_HOME=$PWD/apache-maven-3.9.9
export PATH=$M2_HOME/bin:$PATH

# Build dự án
mvn clean install
