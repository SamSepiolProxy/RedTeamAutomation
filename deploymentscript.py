#!/usr/bin/python

from jinja2 import Environment, FileSystemLoader
import argparse
import os
import json
import sys
from art import *

def get_args():
    parser = argparse.ArgumentParser(description='Azure Red Team Deployment Script')
    parser.add_argument("--deployment", help="Deploy the infrastructure", action="store_true")
    parser.add_argument("--provision", help="Configure the infrastructure", action="store_true")
    parser.add_argument("--harden", help="Harden the infrastructure", action="store_true")
    parser.add_argument("--destroy", help="Destroy the infrastructure", action="store_true")
    parser.add_argument('-d', dest='C2RDRDomain', type=str, required=False, help='C2 Redirector Domain example: test.com')
    parser.add_argument('-w', dest='IPWhitelist', type=str, required=False, help='IP Whitelist to connect ssh example: 127.0.0.1')
    parser.add_argument('-r', dest='resourcename', type=str, required=False, help='The main resource group name example: RedTeam')
    return parser

def deploymenttemplatecompiler(dir, filename, fileoutput):
    env = Environment(loader=FileSystemLoader('templates/' + dir))
    template = env.get_template(filename)
    output_from_parsed_template = template.render(
        C2redirectordomain = args.C2RDRDomain,
        IP = args.IPWhitelist,
        resourcegroupname = args.resourcename
        )
    # Save the results
    with open(fileoutput, "w") as fh:
        fh.write(output_from_parsed_template)

def provisiontemplatecompiler(dir, filename, fileoutput, c2Covprivateip):
    env = Environment(loader=FileSystemLoader('templates/' + dir))
    template = env.get_template(filename)
    output_from_parsed_template = template.render(
        C2redirectordomain = args.C2RDRDomain,
        IP = args.IPWhitelist,
        resourcegroupname = args.resourcename,
        C2CovPrivateIPTemp = c2Covprivateip
        )
    # Save the results
    with open(fileoutput, "w") as fh:
        fh.write(output_from_parsed_template)

def credcheck ():
    MANDATORY_ENV_VARS = ["ARM_CLIENT_ID", "ARM_CLIENT_SECRET", "ARM_SUBSCRIPTION_ID", "ARM_TENANT_ID"]
    for var in MANDATORY_ENV_VARS:
        if var not in os.environ:
            print('Credentials are required:\nexport ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"\nexport ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"\nexport ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"\nexport ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"')
            sys.exit()

    if False == args.deployment == args.provision == args.harden == args.destroy:
        print("Select an option --deployment or -- provision or --harden")
        sys.exit()

def jsonparser(filejson):
    with open(filejson, 'r') as jsonfile:
        jsonfile.seek(0)
        data = json.load(jsonfile)
    return data

def deployment():
    if args.C2RDRDomain is None or args.IPWhitelist is None or args.resourcename is None:
        parser.error("--deployment requires -d , -w and -r.")
    os.system("cp ./templates/terraform/C2-RDR-Initial.tf ./modules/C2RDR/C2-RDR.tf")
    deploymenttemplatecompiler('terraform', 'terraform.tfvars', './terraform.tfvars')
    os.system("terraform init")
    os.system("terraform fmt")
    os.system("terraform plan")
    os.system("terraform  apply -var-file='terraform.tfvars'")
    os.system("terraform output -json > ./output.json")
    parsedfile = jsonparser("output.json")
    C2CovPublicIP = parsedfile["C2CovPublicIP"]["value"]
    C2RDRPublicIP = parsedfile["C2RDRPublicIP"]["value"]
    DNSNamerservers = parsedfile["DNSNameservers"]["value"]
    tprint("Deployment Completed")
    print("Add the following nameservers to your DNS registrar:")
    print(DNSNamerservers)
    print("C2CovPublicIP:"+C2CovPublicIP+"\nC2RDRPublicIP:"+C2RDRPublicIP)

def provision():
    if args.C2RDRDomain is None:
        parser.error("--provision requires -d")
    
    parsedfile = jsonparser("output.json")
    C2CovPrivateIP = parsedfile["C2CovPrivateIP"]["value"]
    C2CovPublicIP = parsedfile["C2CovPublicIP"]["value"]
    C2RDRPublicIP = parsedfile["C2RDRPublicIP"]["value"]
    provisiontemplatecompiler('config/C2RDR', 'default-ssl.conf', './config/C2RDR/default-ssl.conf', C2CovPrivateIP)
    provisiontemplatecompiler('config/C2RDR', 'redirect.rules', './config/C2RDR/redirect.rules', C2CovPrivateIP)
    provisiontemplatecompiler('config/C2RDR', 'redirector-setup.yaml', './config/C2RDR/redirector-setup.yaml', C2CovPrivateIP)
    provisiontemplatecompiler('terraform', 'C2-RDR.tf', './modules/C2RDR/C2-RDR.tf', C2CovPrivateIP)
    os.system("chmod 600 ./keys/id_rsa")
    os.system("chmod 600 ./keys/id_rsa.pub")
    os.system("terraform init")
    os.system("terraform fmt")
    os.system("terraform plan")
    os.system("terraform  apply -var-file='terraform.tfvars'")
    os.system("ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -u redteamuser -i '"+C2CovPublicIP+",' --private-key ./keys/id_rsa config/C2/covenant-setup.yaml")
    os.system("ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -u redteamuser -i '"+C2RDRPublicIP+",' --private-key ./keys/id_rsa config/C2RDR/redirector-setup.yaml")
    tprint("Provision Completed")


if __name__ == '__main__':

    parser = get_args()
    args = parser.parse_args()

    credcheck()

    if args.deployment:
        deployment()

    if args.provision:
        provision()

    if args.destroy:
        os.system('terraform destroy')
