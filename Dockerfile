FROM redfactorlabs/concourse-smuggler-resource:alpine

MAINTAINER "Jo Vanvoorden <jo.vanvoorden@telenet.be>"

COPY smuggler.yml in.sh out.sh check.sh /opt/resource/
