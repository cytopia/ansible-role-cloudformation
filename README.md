# Ansible Role: Create cloudformation stacks

**[Motivation](#motivation)** |
**[Installation](#installation)** |
**[Features](#features)** |
**[Variables](#variables)** |
**[Usage](#usage)** |
**[Templates](#templates)** |
**[Diff](#diff)** |
**[Dependencies](#dependencies)** |
**[Requirements](#requirements)** |
**[License](#license)**

[![Build Status](https://travis-ci.org/cytopia/ansible-cloudformation.svg?branch=master)](https://travis-ci.org/cytopia/ansible-cloudformation)
[![Ansible Galaxy](https://img.shields.io/ansible/role/d/23347.svg)](https://galaxy.ansible.com/cytopia/cloudformation/)
[![Release](https://img.shields.io/github/release/cytopia/ansible-cloudformation.svg)](https://github.com/cytopia/ansible-cloudformation/releases)

Ansible role to render an arbitrary number of [Jinja2](http://jinja.pocoo.org/) templates into [Cloudformation](https://aws.amazon.com/cloudformation/) files and deploy any number of stacks.


## Motivation

This role overcomes the shortcomings of Cloudformation templates itself as well as making heavy use of Ansible's features.

1. **Cloudformation limitations** - The Cloudformation syntax is very limited when it comes to programming logic such as conditions, loops and complex variables such as arrays or dictionaries. By wrapping your Cloudformation template into Ansible, you will be able to use Jinja2 directives within the Cloudformation template itself, thus having all of the beauty of Ansible and still deploy via Cloudformation stacks.
2. **Environment agnostic** - By being able to render Cloudformation templates with custom loop variables you can finally create fully environment agnostic templates and re-use them for production, testing, staging and other environments.
3. **Dry run** - Another advantage of using Ansible to deploy your Cloudformation templates is that Ansible supports a dry-run mode (`--check`) for Cloudformation deployments (since Ansible 2.4). During that mode it will create Change-sets and let you know **what would change** if you actually roll it out. This way you can safely test your stacks before actually applying them.

This role can be used to either only generate your templates via `cloudformation_generate_only` or also additionally deploy your rendered templates. So when you have your deployment infrastructure already in place, you can still make use of this role, by only rendering the templates and afterwards hand them over to your existing infrastructure.

When templates are rendered, a temporary `build/` directory is created inside the role directory. This can either persist or be re-created every time this role is run. Specify the behaviour with `cloudformation_clean_build_env`.


## Installation

Either use [Ansible Galaxy](https://galaxy.ansible.com/cytopia/cloudformation/) to install the role:
```bash
$ ansible-galaxy install cytopia.cloudformation
```

Or git clone it into your roles directory
```bash
$ git clone https://github.com/cytopia/ansible-cloudformation /path/to/ansible/roles
```


## Features
* Deploy arbitrary number of [Cloudformation](https://aws.amazon.com/cloudformation/) templates
* Create Cloudformation templates with [Jinja2](http://jinja.pocoo.org/) templating engine
* Render templates only and use your current infrastructure to deploy
* Dry-run via Ansible `--check` mode which will create temporary Change sets (e.g.: lets you know if a resource requires re-creation)
* Have line-by-line diff between local and deployed templates via [cloudformation_diff](https://github.com/cytopia/ansible-modules) module
* Make use of [Ansible vault](https://docs.ansible.com/ansible/2.4/vault.html) to store sensitive information encrypted


## Variables

### Overview

The following variables are available in `defaults/main.yml` and can be used to setup your infrastructure.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cloudformation_clean_build_env` | bool | `False` | Clean `build/` directory of Jinja2 rendered Cloudformation templates on each run. |
| `cloudformation_generate_only` | bool | `False` | Insteaf of deploying your Cloudformation templates, you can also only render them and have them available in the `build/` directory so you can use your current infrastructure to deploy those templates.<br/>**Hint:** Specify this variable via ansible command line arguments |
| `cloudformation_run_diff` | bool | `False` | This role ships a custom Ansible Cloudformation module **[cloudformation_diff](https://github.com/cytopia/ansible-modules)**. This module generates a text-based diff output between your local cloudformation template ready to be deployed and the currently deployed templated on AWS Cloudformation.<br/>Why would I want this?<br/>The current cloudformation module only list change sets in --check mode, which will let you know what *kind* will change (e.g. security groups), but not what exactly will change (which security groups and the values of them) In order to also be able to view the exact changes that will take place, enable the cloudformation_diff module here. |
| `cloudformation_required` | list | `[]` | Array of available cloudformation stack keys that you want to enforce to be required instead of being optional. Each cloudformation stack item will be checked against the customly set required keys. In case a stack item does not contain any of those keys, an error will be thrown before any deployment has happened. |
| `cloudformation_defaults` | dict | `{}` | Dictionary of default values to apply to every cloudformation stack. Note that those values can still be overwritten on a per stack definition. |
| `cloudformation_stacks` | list | `[]` | Array of cloudformation stacks to deploy. |

### Details

This section contains a more detailed describtion about available dict or array keys.

#### `cloudformation_defaults`

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `aws_access_key` | string | optional | AWS access key to use |
| `aws_secret_key` | string | optional | AWS secret key to use |
| `security_token` | string | optional | AWS security token to use |
| `profile` | string | optional | AWS boto profile to use |
| `notification_arns` | string | optional | Publish stack notifications to these ARN's |
| `region` | string | optional | AWS region to deploy stack to |

#### `cloudformation_stacks`

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `stack_name` | string | required | Name of the cloudformation stack |
| `template` | string | required | Path to the cloudformation template to render and deploy (Does not need to be rendered) |
| `aws_access_key` | string | optional | AWS access key to use (overwrites default) |
| `aws_secret_key` | string | optional | AWS access key to use (overwrites default)  |
| `security_token` | string | optional | AWS security token to use (overwrites default) |
| `profile` | string | optional | AWS boto profile to use (overwrites default) |
| `notification_arns` | string | optional | Publish stack notifications to these ARN's (overwrites default) |
| `region` | string | optional | AWS region to deploy stack to (overwrites default) |
| `template_parameters` | dict | optional | Required cloudformation stack parameters |
| `tags` | dict | optional | Tags associated with the cloudformation stack |

### Examples

Define default values to be applied to all stacks (if not overwritten on a per stack definition)
```yml
# Enforce that 'profile' must be set for each cloudformation stack item
cloudformation_required:
  - profile

cloudformation_defaults:
  region: eu-central-1
```


Define cloudformation stacks to be rendered and deployed
```yml
cloudformation_stacks:
  - stack_name: stack-s3
    template: files/cloudformation/s3.yml.j2
    profile: production
    template_parameters:
      bucketName: my-bucket
    tags:
      env: production
  - stack_name: stack-lambda
    template: files/cloudformation/lambda.yml.j2
    profile: production
    template_parameters:
      lambdaFunctionName: lambda
      handler: lambda.run_handler
      runtime: python2.7
      s3Bucket: my-bucket
      s3Key: lambda.py.zip
    tags:
      env: production
```

Only render your Jinja2 templates, but do not deploy them to AWS. Rendered cloudformation files will be inside the `build/` directory of this role.
```bash
$ ansible-playbook play.yml -e cloudformation_generate_only=True
```

## Usage

### Simple

Basisc usage example:

`playbook.yml`
```yml
- hosts: localhost
  connection: local
  roles:
    - cloudformation
```

`group_vars/all.yml`
```yml
cloudformation_defaults:
  profile: testing
  region: eu-central-1

cloudformation_stacks:
  - stack_name: stack-s3
    template: files/cloudformation/s3.yml.j2
    template_parameters:
      bucketName: my-bucket
    tags:
      env: "{{ cloudformation_defaults.profile }}"
  - stack_name: stack-lambda
    template: files/cloudformation/lambda.yml.j2
    template_parameters:
      lambdaFunctionName: lambda
      handler: lambda.run_handler
      runtime: python2.7
      s3Bucket: my-bucket
      s3Key: lambda.py.zip
    tags:
      env: "{{ cloudformation_defaults.profile }}"
```

### Advanced

Advanced usage example calling the role independently in different *virtual* hosts.

`inventory`
```ini
[my-group]
infrastructure  ansible_connection=local
application     ansible_connection=local
```

`playbook.yml`
```yml
# Infrastructure part
- hosts: infrastructure
  roles:
    - cloudformation
  tags:
    - infrastructure

# Application part
- hosts: application
  roles:
    - some-role
  tags:
    - some-role
    - application

- hosts: application
  roles:
    - cloudformation
  tags:
    - application
```

`group_vars/my-group.yml`
```yml
stack_prefix: testing
boto_profile: testing
s3_bucket: awesome-lambda

cloudformation_defaults:
  profile: "{{ boto_profile }}"
  region: eu-central-1
```

`host_vars/infrastructure.yml`
```yml
cloudformation_stacks:
  - stack_name: "{{ stack_prefix }}-s3"
    template: files/cloudformation/s3.yml.j2
    template_parameters:
      bucketName: "{{ s3_bucket }}"
    tags:
      env: "{{ stack_prefix }}"
```

`host_vars/application.yml`
```yml
cloudformation_stacks:
  - stack_name: "{{ stack_prefix }}-lambda"
    template: files/cloudformation/lambda.yml.j2
    template_parameters:
      lambdaFunctionName: lambda
      handler: lambda.run_handler
      runtime: python2.7
      s3Bucket: "{{ s3_bucket }}"
      s3Key: lambda.py.zip
    tags:
      env: "{{ stack_prefix }}"
```


## Templates

This section gives a brief overview about what can be done with Cloudformation templates using Jinja2 directives.

### Example: Subnet definitions

The following template can be rolled out to different staging environment and is able to include a different number of subnets.

Ansible variables
```yml
---
# file: staging.yml
vpc_subnets:
  - directive: subnetA
    az: a
    cidr: 10.0.10.0/24
    tags:
      - name: Name
        value: staging-subnet-a
      - name: env
        value: staging
  - directive: subnetB
    az: b
    cidr: 10.0.20.0/24
    tags:
      - name: Name
        value: staging-subnet-b
      - name: env
        value: staging
```

```yml
---
# file: production.yml
vpc_subnets:
  - directive: subnetA
    az: a
    cidr: 10.0.10.0/24
    tags:
      - name: Name
        value: prod-subnet-a
      - name: env
        value: production
  - directive: subnetB
    az: b
    cidr: 10.0.20.0/24
    tags:
      - name: Name
        value: prod-subnet-b
      - name: env
        value: production
  - directive: subnetC
    az: b
    cidr: 10.0.30.0/24
    tags:
      - name: Name
        value: prod-subnet-c
      - name: env
        value: production
```

Cloudformation template
```jinja
AWSTemplateFormatVersion: '2010-09-09'
Description: VPC Template
Resources:
  vpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: {{ vpc_cidr_block }}
      EnableDnsSupport: true
      EnableDnsHostnames: true
{% if vpc_tags %}
      Tags:
{% for tag in vpc_tags %}
        - Key: {{ tag.name }}
          Value: {{ tag.value }}
{% endfor %}
{% endif %}
{% for subnet in vpc_subnets %}
  {{ subnet.directive }}:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: {{ subnet.az }}
      CidrBlock: {{ subnet.cidr }}
      VpcId: !Ref vpc
{% if subnet.tags %}
      Tags:
{% for tag in subnet.tags %}
        - Key: {{ tag.name }}
          Value: {{ tag.value }}
{% endfor %}
{% endif %}
```


### Example: Security groups

Defining security groups with IP-specific rules is very difficult when you want to keep environment agnosticity and still use the same Cloudformation template for all environments. This however can easily be overcome by providing environment specific array definitions via Jinja2.

Ansible variables
```yml
---
# file: staging.yml
# Staging is wiede open, so that developers are able to
# connect from attached VPN's
security_groups:
  - protocol:  tcp
    from_port: 3306
    to_port:   3306
    cidr_ip:   10.0.0.1/32
  - protocol:  tcp
    from_port: 3306
    to_port:   3306
    cidr_ip:   192.168.0.15/32
  - protocol:  tcp
    from_port: 3306
    to_port:   3306
    cidr_ip:   172.16.0.0/16
```

```yml
---
# file: production.yml
# The production environment has far less rules as well as other
# ip ranges.
security_groups:
  - protocol:  tcp
    from_port: 3306
    to_port:   3306
    cidr_ip:   10.0.15.1/32
```

Cloudformation template
```jinja
AWSTemplateFormatVersion: '2010-09-09'
Description: VPC Template
Resources:
  rdsSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: RDS security group
{% if security_groups %}
      SecurityGroupIngress:
{% for rule in security_groups %}
        - IpProtocol: "{{ rule.protocol }}"
          FromPort: "{{ rule.from_port }}"
          ToPort: "{{ rule.to_port }}"
          CidrIp: "{{ rule.cidr_ip }}"
{% endfor %}
{% endif %}
```

## Diff

When having enable `cloudformation_run_diff`, you will be able to see line by line diff output from you local (jinja2 rendered) template against the one which is currently deployed on AWS. To give you an impression about how this looks, see the following example output:

```diff
--- before
+++ after
@@ -38,7 +38,6 @@
             "Type": "AWS::S3::BucketPolicy"
         },
         "s3Bucket": {
-            "DeletionPolicy": "Retain",
             "Properties": {
                 "BucketName": {
                     "Ref": "bucketName"
```


## Dependencies

This role does not depend on any other roles.


## Requirements

Use at least **Ansible 2.4** in order to also have `--check` mode for cloudformation.

The python module `cfn_flip` is required, when using line-by-line diff of local and remote Cloudformation templates (`cloudformation_run_diff=True`). This can easily be installed locally:
```bash
$ pip install cfn_flip
```


## License

[MIT License](LICENSE.md)

Copyright (c) 2017 [cytopia](https://github.com/cytopia)
