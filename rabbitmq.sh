$LOGS_FOLDER=/var/log/roboshop
sudo mkdir -p $LOGS_FOLDER
chown -R ec2-user:ec2-user $LOGS_FOLDER
chmod -R 755 $LOGS_FOLDER
LOG_FILE=$LOGS_FOLDER/$0.log

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S)

if [ $USERID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R please run this script with root user $N" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE(){
    if [$1 -ne 0]; then
        echo -e "$TIMESTAMP [ERROR] $2...$R FAILURE $N" | tee -a $LOG_FILE
    else
        echo -e "$TIMESTAMP [INFO] $2 ... $G SUCCESS $N" | tee -a $LOG_FILE    
    fi
}   


cp -rp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo

dnf install rabbitmq-server -y
VALIDATE $? "Installing RabbitMQ server"

systemctl enable rabbitmq-server &>> $LOG_FILE
systemctl start rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Enabling and starting rabbitmq server"

rabbitmqctl add_user roboshop roboshop123 &>> $LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE
VALIDATE $? "roboshop user password set"
