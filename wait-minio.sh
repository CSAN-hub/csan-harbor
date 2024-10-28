#!/bin/bash

# Install and configure Harbor

# @author  Fabrice Jammes

set -euxo pipefail

timeout=240
wait_time=5

while true
do
  ink "Wait for minio s3 endpoint to be ready"
  endpoints=$(kubectl get endpoints -l v1.min.io/tenant=minio -n minio -o jsonpath="{range .items[*]}{.subsets[*].addresses[*].ip}{'\n'}{end}")
  if [ "$endpoints" ]; then
    break
  fi
  ink "Minio endpoints not found, retrying in $wait_time seconds"
  sleep $wait_time
done

ink "Wait for minio s3 bucket 'harbor' to exist"
kubectl exec -it  s5cmd --env AWS_ACCESS_KEY_ID=minio --env  AWS_SECRET_ACCESS_KEY=minio123 --env S3_ENDPOINT_URL=https://minio.minio:443 --command -- sleep infinity

while true
do
  kubectl exec -it  s5cmd -- /s5cmd --log debug --no-verify-ssl ls "s3://harbor/*"
  if [ $? -eq 0 ]; then
    break
  else
    ink "Bucket 'harbor' not found, retrying in $wait_time seconds"
    sleep $wait_time
  fi
done

