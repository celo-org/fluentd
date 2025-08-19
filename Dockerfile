FROM fluent/fluentd:v1.16-debian-1
USER root
RUN apt-get update && apt-get install -y python3-pip \
 && gem install fluent-plugin-gcloud-pubsub-custom \
 && pip install --break-system-packages google-cloud-storage 
