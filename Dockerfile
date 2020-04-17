FROM ubuntu:16.04

RUN apt-get update && apt-get install --no-install-recommends -y \
	git \
	curl \
	awscli \
	git \
	nginx \
	vim \
	cron \
	supervisor

# RUN pip install localstack awscli awscli-local --upgrade; exit 0
# RUN pip3 install awscli-local; exit 0
# RUN apt-get --reinstall install python3-setuptools python3-wheel python3-pip

COPY .aws /root/.aws
COPY aws-resource-init.sh /root/aws-resource-init.sh
COPY lambda.zip /root/lambda.zip
RUN chmod +x /root/aws-resource-init.sh

WORKDIR /root
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && apt-get update && apt-get install -y nodejs
RUN npm install -g pm2
RUN git clone https://github.com/thxwelchs/kinesis-lambda-logging.git
WORKDIR /root/kinesis-lambda-logging/producer
RUN npm install

WORKDIR /root

ENV LOCALSTACK_HOST 192.168.99.100

COPY stream-producer.sh /root/stream-producer.sh
RUN chmod +x /root/stream-producer.sh

ADD crontab /etc/cron.d/kinesis-producer-cron
RUN chmod 0644 /etc/cron.d/kinesis-producer-cron

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# COPY cron-init.sh /root/cron-init.sh
# RUN chmod +x /root/cron-init.sh


CMD ["/usr/bin/supervisord"]

EXPOSE 80

