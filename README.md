# cloud-code-challenge
Messing around with a challenge I got via email,  this was done in around 6hrs of work: 

* **Terraform**, runs as intended, might need to change lines 40, 49 & 70 to make it work in any other region =! us-west-1
* **MySQL**, Schema was built, found it in several online tutorials including the official MySQL documentation 
* **App**, This is actually my 1st attemp at builting an API, was a nice excercise however its not pulling the data from MySQL its hardcoded in the Json Itself 

Im pretty sure is enough to get a conversation going, challenge is vague in many ways and It can take up to 6 hours or 1 week or several months if taken seriously, so Im calling it a day after 6hrs, heres I have documented my answers the challenge bulletpoints:


## A) Create a public repo for this exercise
https://github.com/vazeri/cloud-code-challenge

## B) Write a script to deploy the Infrastructure as code 
This can be found here https://github.com/vazeri/cloud-code-challenge/tree/main/terraform

In order to run the terraform script AWS secrets have been setup as environment variables 
**Debian, Ubuntu**
```console
export AWS_ACCESS_KEY_ID=***********************
export AWS_SECRET_ACCESS_KEY=*******************
```

## C) Write a script to deploy the application
A rest API was generatrd to serve as an aplication endpoint, it was provided as a JSON file, 
https://github.com/vazeri/cloud-code-challenge/tree/main/API

This can be deployed directly on the system startup using a bash shell script using the EC2 starting parameters on the instance launch I drafted a possible solution, didnt actually went to finish this part but It would look something around this:

```console
if ${abortStartup}; then
    aws autoscaling complete-lifecycle-action --lifecycle-action-result ABANDON --instance-id ${INSTANCEID} --lifecycle-hook-name warmup --auto-scaling-group-name ${ASG} --region ${REGION}
else
    TESTING_PASSWORD=$(aws ssm get-parameter --with-decryption --name smoke_testing_pwd_${ENV} --region ${REGION} | jq -r ".Parameter.Value")
    x=1

    d=$(date)
    echo "${d}: Starting warm-up..."

    while [ $x -le 40 ]
    do
        web=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 http://localhost:8080/version)
        pet=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 -H "Authorization: Basic ${TESTING_PASSWORD}" -H "Accept: application/json" -H "Content-Type: application/json" http://localhost:8080/api/pet)
        pets=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 -H "Authorization: Basic ${TESTING_PASSWORD}" -H "Accept: application/json" -H "Content-Type: application/json" http://localhost:8080/api/pets)

        d=$(date)
        echo "${d}: Web: ${web} - Pet: ${pet} - Pets: ${pets}"

        if [ ${Web} == "200" ] || [ ${pet} == "200" ] || [ ${pets} == "200" ] || [ ${web} == "200" ]; then
            sleep 5
            d=$(date)
            echo "${d}: Warmed up, putting instance into service"
            break
        else
            d=$(date)
            echo "${d}: API has not fully started, waiting 20 seconds before trying again..."
    
            sleep 20
            ((x++))
        fi
        
    done
```


## D) Security upgrades need to be performed every now and then 

This can be achieved by installing both AWS SSM agent for Operative system updates

```
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
```
AWS Inspector Agent for security vulnerabilities in the infrastructure 

```
wget https://inspector-agent.amazonaws.com/linux/latest/install
sudo bash install
rm -f install
```

Once setup these tasks needs to be delegated to the operational team for maintenance and keeping the infrastructure and OS layer of the system udpated 


# Extra points

## 1) How would you expose your app to the internet 

DNS record pointing to a Loadbalancer in a public subnet, that can re route the trafic to the private subnets 

## 2) What would you use to dynamacaly scale your application

Load balancers for both EC2 instances that have the App and migrate the database to an Aurora Database isntead of a simple RDS database 

During the development several alternatives where used to test the Mysql Queris in botu aurora and aurora severless leaving th ecoe here for future works 

```console
resource "aws_rds_cluster" "default" {
  cluster_identifier      = "code-challenge-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  availability_zones      = ["us-west-1b", "us-west-1c"]
  database_name           = "mydb"
  master_username         = "foo"
  master_password         = "bar12345678"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  db_subnet_group_name    = "code-challenge-subnet-group"
}
```

## 3) How would you grant access to a developer to the database 

Create a pipeline of environments, DEV -> UAT -> PROD, Grant developers full access to DEV and UAT, and provide them tools to restore production snapshots to the DEV & UAT environments in case the screw something up by mistake 

## 4) Build v2 of the application 

Would love to but v1 wasnt even finished and its time for dinner, family requires attention too!



## References

https://www.linkedin.com/pulse/launching-infrastructure-aws-custom-vpc-internet-gateway-agarwal?trk=public_profile_article_view

https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-launch-managed-instance.html

https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/launch-more-like-this.html

