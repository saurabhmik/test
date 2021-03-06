import json
import requests
import sys
import warnings



# Define Octopus server variables
octopus_server_uri = sys.argv[1] # 'http://octopus/' 
octopus_server_uri = octopus_server_uri + '/api'
octopus_api_key =  sys.argv[2] #'API-xxx'

headers = {'X-Octopus-ApiKey': octopus_api_key}


def get_octopus_resource(uri):
    response = requests.get(uri, headers=headers)
    response.raise_for_status()

    return json.loads(response.content.decode('utf-8'))


def get_by_name(uri, name):
    resources = get_octopus_resource(uri)
    return next((x for x in resources if x['Name'] == name), None)


space_name = ''
prefix = sys.argv[3] #TentacleName

topology = sys.argv[4] #Topology type
print("prefix is:",prefix)
print("topology is:",topology)

if topology == "small":
    targets = [prefix+"-appvm"]
elif topology == "medium":
    targets = [prefix+"-appvm", prefix+"-dbvm"]
elif topology == "large":
    targets = [prefix+"-appvm", prefix+"-dbvm", prefix+"-rmqvm"]
else:
    print("topology does not match any defined ones:small,medium or large")
    sys.exit()
        
space = get_by_name('{0}/spaces/all'.format(octopus_server_uri), space_name)
print ("Tentacles to be deleted:",targets)

for target_name in targets:
    target = get_by_name('{0}/{1}/machines/all'.format(octopus_server_uri, space['Id']), target_name)
    if target:
        print ("Deleting Target:",target_name)
        print ('Tentacle Found:',target_name,'with Target-ID:',target['Id'])
        uri = '{0}/{1}/machines/{2}'.format(octopus_server_uri, space['Id'], target['Id'])
        response = requests.delete(uri, headers=headers)
        response.raise_for_status()
        print(target_name,'Tentacle has been deleted')
    else:
        print(target_name,'Tentacle was not found')
        warnings.warn('Tentacle was not found')