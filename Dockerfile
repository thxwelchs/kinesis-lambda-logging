FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get install -y awscli
RUN apt-get install -y git
RUN apt install -y default-jdk; exit 0
# RUN apt-get install -y openjdk-8-jre
# RUN export JAVA_HOME=$(update-java-alternatives --list | grep java-1.8 | awk '{ print $3 }') && export PATH=$JAVA_HOME/bin:$PATH

WORKDIR /root

RUN git clone https://github.com/awslabs/amazon-kinesis-agent.git
WORKDIR /root/amazon-kinesis-agent
RUN ./setup --install; exit 0

# RUN ./setup --install

WORKDIR /etc/nginx

CMD ["nginx", "-g", "daemon off;"]

EXPOSE 80

