Build Smart With AWS & Puppet
=============================

This repository conatins code examples used in the AWS conference 
talks and tutorials by Ben Waine. 

To get started clone this repository and follow the instructions
below to get started with puppet.

## Requirments

These examples have been tested using:

- Vagrant v-1.4.3
- Virtualbox v-4.2.10
- Puppet 

1) Install vagrant - http://docs.vagrantup.com/v2/getting-started/index.html

2) Install Virtual Box - https://www.virtualbox.org/wiki/Downloads

3) Install the base box
 - vagrant box add awsbase https://www.dropbox.com/s/p5n53yu85j75mwj/awspuppetbase.box

The base box has ubuntu 12.10 and puppet installed. It is the base 
installation used to carry out the steps bellow. If you are interested in building
your own base box check out the excellent tool created by Patrick Debois called
Veewee - https://github.com/jedi4ever/veewee.

## Creating A Local Puppet Development Environment

The following steps produce a virtual machine which serves as a local
puppet master. You can use the local puppet master to test manifests
and configuration locally before testing them in the cloud.

### Creating A Local Puppet Master

These steps run a puppet master in test mode, outputting a lot of usefull
debug information to the console. 

1) cd puppet-master

2) vagrant up

3) vagrant ssh

4) cd /vagrant

5) puppet master --no-daemonize --debug --config=puppet.conf
 - Run puppet in the foreground with debug output
 - Uses config from the codebase rather than looking in the users homedir 


### Creating A VM From Puppet

Vagrant allows us to easily create and tear down VM's. Once a VM is created
we can provision it against the local puppet master created above. 
If an error occurs we can address it in the puppet master code and tear down 
the VM and start again fresh.

This is important becuase in the cloud environment puppet must run once, cleanly
without any administrator intervention. 

1) cd puppet-agent

2) vagrant up

3) vagrant ssh

4) sudo puppet agent --config=/vagrant/puppet.conf -t --certname [ROLENAME].[ATTEMPT-NUMBER]
 - eg: sudo puppet agent --config=/vagrant/puppet.conf -t --certname webserver.44

Command (4) runs puppet master in test mode, using the config file in /vagrant providing useful 
debugging output to the console.

- ROLENAME: This should match the name of a node manifest eg - Webserver

- ATTEMPT-NUMBER: Puppet generates an SSL certificate for each "certname"
it recieves and caches it. Incrementing this number everytime we create a 
box means we don't have to clear certificates on the master each time. 

Note: The puppet.conf file on master takes care of some simple config including 
node and module paths, hostname of the master and the location of the master
on the agent. 

### Webserver

The above steps created a webserver by running the 'webserver' node manifest on the VM 
we created when we vagrant up'ed. You can check this by adding '192.168.50.103 test.webserver.dev'
to your hosts file and navigate to test.weserver.dev in your browser. This is just 
a simple example, your node manifests will likley be much more complex! 

## Creating An AMI Build Environment On AWS

In order to build AMI's in the cloud we need to set up some AWS 
infrastructure, create a puppet master and a base AMI (with puppet agent installed).

### Creating All Necissery Networking / AWS infrastructure. 

Use the cloud formation template "./cloudformation/01-AMIBUILD.json" to 
create a VPC, subnets and security groups.

This process may seem a little magical, see the explanation at the end 
of the tutorial for a summary of the resources created in these steps. 

1) Log into the aws managment console - https://console.aws.amazon.com/console/home

2) Select 'Cloud Formation' from the 'Services' menu. 

3) Select your prefered region from the region menu in the upper left hand corner.
 - Chose a region close to. EG - I chose EU (Ireland)

4) Enter a stackname into the input box

5) Select 'Upload Template' and upload the "01-AMIBUILD.json" template

6) Wait for the stack to complete. 

### Creating A Base AMI

This section creates our base AMI used to create the puppet master and 
as the basis for our other AMI's.

1) Log into the aws managment console - https://console.aws.amazon.com/console/home

2) Select 'EC2' from the 'Services' menu

3) Select your prefered region from the region menu in the upper left hand corner. 
 - This much match the regioun you chose in the previous section.

3) Select 'Instances' from the left hand nav.

4) Click the blue 'Launch Instance' button 

5) Select 'Comunity AMIs' from the left hand nav

6) Select an ubuntu 12.10 EBS backed instance
 - You can find the name of the AMI to search for from the Canonical site http://cloud-images.ubuntu.com/locator/ec2/
 - AMI ID's vary from region to region. Make sure you select the correct region and the 'ebs' instance type.
 - In eu-west-1 the ami for ubuntu 12.10 (ebs backed) is ami-67629010

7) Select 't1.micro' and click 'Next: Configure Instance Details'

8) Select "t1.micro" and click "Next: Configure Instance Details"
 - t1.micro is in the free tier. For your prod environments choose a bigger instance type.

9) This screen configures all the instance parameters: 
 - Number of Instances: 1
 - Spot instances: no
 - Network: select the VPC created in the previous step
 - Public IP: YES
 - IAM Role: None
 - Shutdown Behaviour: Stop
 - Termination Protection: No
 - Monitoring: No
 - Tenancy: Shared

10) Click "Next: Add Storage", "Next: Tag Instance", "Next: Configure Security Group"

11) Click "Select an existing security group" and choose the one created by cloud formation

12) Click review and launch. (Create a SSH key here if required)

13) SCP the "provision.sh" script to the newly reated instance.
 - eg: scp -i /path/to/key.pem provision.sh ubuntu@[INSTANCE-IP]:~

14) ssh into the newly created instance using the key you created. 
 - eg: ssh -i /path/to/key.pem ubuntu@[INSTANCE-IP]

15) You may need to make the "provision.sh" scrip executable
 - eg: chmod +x provision.sh

16) Run the "provision.sh" script
 - eg: sudo ./provision.sh

17) In the AWS managment console right click on the instance and select 'Create Image'

19) Give the image an appropriate name.
 - I like to use semantic versioning. 
 - Eg: base v-0-0-1

These steps have created an AMI, running Ubuntu 12.10 with Puppet installed. 
The AMI has this baked into the hosts file to keep this tutorial simple. 
Setting up DNS for a more robust setup is left as an excersise for the reader.  

### Creating A Puppet Master On AWS

In this section we use the Base AMI to create a puppet master for the AMI build environment. 

1) Log into the aws managment console - https://console.aws.amazon.com/console/home

2) Select 'EC2' from the 'Services' menu

3) Select your prefered region from the region menu in the upper left hand corner. 
 - This much match the regioun you chose in the previous section.

3) Select 'Instances' from the left hand nav.

4) Click the blue 'Launch Instance' button 

5) Select "t1.micro" and click "Next: Configure Instance Details"
 - t1.micro is in the free tier. For your prod environments choose a bigger instance type.

6) This screen configures all the instance parameters: 
 - Number of Instances: 1
 - Spot instances: no
 - Network: select the VPC created in the previous step
 - Public IP: YES
 - IAM Role: None
 - Shutdown Behaviour: Stop
 - Termination Protection: No
 - Monitoring: No
 - Tenancy: Shared

7) Unlike the previous section we need to specify a particular private IP address
for our puppet master (as it was hardcoded into the hosts file in the previous step).
- In the "Network Interfaces" section add the "Primary IP": 10.0.1.100.

7) Click "Next: Add Storage", "Next: Tag Instance", "Next: Configure Security Group"

8) Click "Select an existing security group" and choose the one created by cloud formation

9) Click review and launch.

10) SCP the puppet-master folder to the new instance
 - eg: scp -r -i /path/to/key.pem puppet-master ubuntu@[INSTANCE-IP]:~
 - In your actual deployment you can automate the deployment of changes to your puppet folder

11) SSH into the new instance
 - eg: ssh -i /path/to/key.pem ubuntu@[INSTANCE-IP]

12) Start the puppet master
 - eg: puppet master --config=/home/ubuntu/puppet-master/puppet-ec2.conf
 - This starts the puppet master deamon, when you logout puppet will continue to run
 - In your real deployment you may want to run puppet under supervise 

## Using Puppet In A Prod Environment

In this section we discuss how to create an AMI using the base AMI and the newly
created puppet master.

1) Log into the aws managment console - https://console.aws.amazon.com/console/home

2) Select 'EC2' from the 'Services' menu

3) Select your prefered region from the region menu in the upper left hand corner. 
 - This much match the regioun you chose in the previous section.

3) Select 'Instances' from the left hand nav.

4) Create an instance as in previous steps, remember to set a public IP. 

5) SSH into the new instance
 - eg: ssh -i /path/to/key.pem ubuntu@[INSTANCE-IP]

6) Run the puppet agent specifying the type of AMI you wish to create
 - eg: sudo puppet agent -t --certname webserver.[VERSION-NUMBER]

7) When the puppet run has sucesfully completed go to the AWS managment console
right click on the instance and click 'Create Image'. Give the image a name. 
 - eg: Remember semantic versioning is your friend.
 - webserver v-0-0-1

8) Click 'AMIs' on the left hand nav and wait for the new AMI to finish 'pending'. 

9) The AMI is now available for you to use for any deployment in the selected region.

## Web App Code & Configuration? 

You should make your own decision on how to deploy application code. Some people choose
to bake the web application code into thier AMIs, some prefer to have a seperate deployment
process which deploys code onto instances based on thier webserver AMIs. 

You should also think about how you will manage configuration in your production environment. 
Some people choose to use puppet to manage config, others bake config into thier AMIs and 
still others choose to use some kind of service discovery mechanism. 

Theese two points could both be tutorials in themselves here are some links to discussion 
pieces. 

- [link]
- [link]

## Automation 

The process outlined above is very manual. The best Devops Engineers are very lazy. 
I've recently developed a console app which automates the steps above and outputs 
the ID of a finished AMI at the end of the process. 

Hopefully I'll find some time in the coming weeks to open source this work. However
the instructions above can form the basis of your own automation efforts.   

## Cloud Formation: Whats is it doing? 

Cloud formation sets up the following resources:

1. VPC - A private network address space which instances are launched into
2. A subnet - An address space within your VPC to launch instances into
3. An Internet gateway - A gateway to allow your instances to communicate outside the VPC
4. A routing table - to route traffic from your subnet to the internet gateway.
5. A security group - controlls access to instances when they are launched into it. 

## Notes HA Puppet & DNS Set up
