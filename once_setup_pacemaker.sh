#!/bin/bash

pcs cluster auth controller1 controller2 controller3 -u hacluster -p password --force
pcs cluster setup --name OpenstackCluster controller1 controller2 controller3
pcs cluster start --all
pcs cluster enable --all

pcs property set stonith-enabled=false
crm_verify -L -V
