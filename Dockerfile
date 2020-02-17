FROM ubuntu:16.04
MAINTAINER manju <manju.gudugunti@gmail.com>

#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu xenial main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu xenial-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu xenial-security main universe\n" >> /etc/apt/sources.list

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    ca-certificates \
    sudo \
    unzip \
    wget \
    python2.7 \
    python-pip \
    git \
    locales \
    xvfb \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Install a basic SSH server
RUN  apt-get update -qqy && \
     apt-get install -qy openssh-server && \
     sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
     mkdir -p /var/run/sshd && \
#  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security
    adduser --quiet jenkins && \
# Set password for the jenkins user (you may want to alter this).
    echo "jenkins:jenkins" | chpasswd && \
    mkdir /home/jenkins/selenium && \
    mkdir /opt/selenium

ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ARG CHROME_DRIVER_VERSION="latest"
RUN CD_VERSION=$(if [ ${CHROME_DRIVER_VERSION:-latest} = "latest" ]; then echo $(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE); else echo $CHROME_DRIVER_VERSION; fi) \
  && echo "Using chromedriver version: "$CD_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CD_VERSION/chromedriver_linux64.zip \
  && rm -rf /opt/selenium/chromedriver \
  && sudo unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CD_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CD_VERSION \
  && sudo ln -fs /opt/selenium/chromedriver-$CD_VERSION /usr/bin/chromedriver

#WORKDIR /home/jenkins
COPY .ssh/authorized_keys /home/jenkins/.ssh/authorized_keys
COPY requirement.txt /home/jenkins/requirements.txt
RUN  pip install -r /home/jenkins/requirements.txt
RUN chown -R jenkins:jenkins /home/jenkins/* && \
    chown -R jenkins:jenkins /home/jenkins/.ssh/ && \
    chown -R jenkins:jenkins /opt/selenium
EXPOSE 4444
#==========
# Selenium
#==========
#RUN  mkdir -p /opt/selenium
#COPY /root/manju/requirements.txt /opt/selenium/requirements.txt
#RUN  pip install -r /opt/selenium/requirements.txt
#  && wget --no-verbose https://selenium-release.storage.googleapis.com/3.0-beta4/selenium-server-standalone-3.0.0-beta4.jar -O /opt/selenium/selenium-server-standalone.jar

#========================================
# Add normal user with passwordless sudo
##========================================
#RUN sudo useradd seluser --shell /bin/bash --create-home \
#  && sudo usermod -a -G sudo seluser \
#  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
#  && echo 'seluser:secret' | chpasswd

#USER root
#ARG CHROME_VERSION="google-chrome-stable"
#RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
#  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
#  && apt-get update -qqy \
#  && apt-get -qqy install \
#    ${CHROME_VERSION:-google-chrome-stable} \
#  && rm /etc/apt/sources.list.d/google-chrome.list \
#  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
#
#USER root
#
##============================================
## Chrome webdriver
##============================================
## can specify versions by CHROME_DRIVER_VERSION
## Latest released version will be used by default
##============================================
#ARG CHROME_DRIVER_VERSION="latest"
#RUN CD_VERSION=$(if [ ${CHROME_DRIVER_VERSION:-latest} = "latest" ]; then echo $(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE); else echo $CHROME_DRIVER_VERSION; fi) \
#  && echo "Using chromedriver version: "$CD_VERSION \
#  && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CD_VERSION/chromedriver_linux64.zip \
#  && rm -rf /opt/selenium/chromedriver \
#  && sudo unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
#  && rm /tmp/chromedriver_linux64.zip \
#  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CD_VERSION \
#  && chmod 755 /opt/selenium/chromedriver-$CD_VERSION \
#  && sudo ln -fs /opt/selenium/chromedriver-$CD_VERSION /usr/bin/chromedriver
#
#EXPOSE 4444
