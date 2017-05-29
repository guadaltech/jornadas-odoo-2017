#!/usr/bin/python
# -*- coding: utf-8 -*-

# Juan Manuel Torres - https://github.com/Tedezed

from oauth2client.client import GoogleCredentials
from googleapiclient import discovery

def list_instances(compute, project, zone):
    result = compute.instances().list(project=project, zone=zone).execute()
    return result

def list_disks(compute, project, zone):
    result = compute.disks().list(project=project, zone=zone).execute()
    return result

def createDisk(compute, project, zone, disk_name, sizeGb):
  config = {
    'name': disk_name,
    "sizeGb": sizeGb,
  }

  return compute.disks().insert(
    project=project,
    zone=zone,
    body=config).execute()