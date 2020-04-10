#!/bin/bash

instance_id=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
aws ec2 associate-address --instance-id $instance_id --allocation-id ${eip} --region ${region} --allow-reassociation
sleep 10
sudo sed -i 's/127.0.0.53/8.8.8.8/g' /etc/resolv.conf
aws ec2 modify-instance-attribute --instance-id $instance_id --no-source-dest-check --region ${region}
