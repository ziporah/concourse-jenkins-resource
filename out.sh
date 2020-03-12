#!/bin/bash

set -e

exec 3>&1
exec 1>&2

set +x

port=""
if [[ -n "${SMUGGLER_port}:-" ]]; then
  port=":${SMUGGLER_port}"
fi

JENKINS_CRUMB=$(curl -s --user "${SMUGGLER_user}:${SMUGGLER_pass}" "${SMUGGLER_protocol:-https}://${SMUGGLER_host}${port}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

job_url="${SMUGGLER_protocol:-https}://${SMUGGLER_host}${port}${SMUGGLER_job}"

if [[ -n "${SMUGGLER_buildParams:-}" ]]; then
  set -x
  curl -sS -X POST -D headers --max-time 10 --retry 3 --user "${SMUGGLER_user}:${SMUGGLER_pass}" -H "$JENKINS_CRUMB" -H "Content-Type: text/xml" -n "${job_url}/buildWithParameters" -d "${SMUGGLER_buildParams}" 
  set +x
else
  set -x
  curl -sS -X POST -D headers --max-time 10 --retry 3 --user "${SMUGGLER_user}:${SMUGGLER_pass}" -H "$JENKINS_CRUMB" -H "Content-Type: text/xml" -n "${job_url}/build" -d ""
  set +x
fi

queue=$(grep '^Location: ' headers | cut -d ' ' -f 2- | sed -e 's/[[:space:]]*$//')

n=0
until [[ $n -ge 20 ]]; do
  set -x
  jobid=$(curl -sS --max-time 10 --retry 3 --user "${SMUGGLER_user}:${SMUGGLER_pass}" -X POST -H "$JENKINS_CRUMB" -H "Content-Type: text/xml" -n "${queue}/api/json" -d "" | jq '.executable.number')
  set +x

  if [[ "${jobid}" == "null" ]]; then
    echo "Build is not scheduled yet ${n}/20" >&2
    sleep 3
  else
    echo "Build scheduled, jobid ${jobid}" >&2
    echo "${jobid}" > "${SMUGGLER_OUTPUT_DIR}/versions"
    break
  fi
done
