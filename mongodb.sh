#!/bin/bash

LOG_DIR="/var/log/roboshop"
sudo mkdir -p $LOG_DIR
sudo chown -R ec2-user:ec2-user $LOG_DIR
sudo chmod -R 755 $LOG_DIR
LOG_FILE="$LOG_DIR/$0.log"

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
n="\e[0m"
TIME_STAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [$USERID -ne 0] ; then
    echo -e "$TIMESTAMP [ERROR] $R please run this script as a root user $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

sudo cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repot"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "installing mongoDB"

systemctl enable --now mongod
VALIDATE $? "starting and enabling mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "allow remote connections to mongoDB"

systemctl restart mongod
VALIDATE $? "restarting mongoDB"

