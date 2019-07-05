#!/bin/bash

echo "**** Begin of Java Install"

echo "**** Install java"
sudo apt-get install openjdk-9-jdk -y > /dev/null 2>&1

echo "**** Install maven"
sudo apt-get install maven -y > /dev/null 2>&1

echo "**** End of Java Install"