LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
chown -R ec2-user:ec2-user $LOGS_FOLDER
chomd -R 755 $LOGS_FOLDER
LOGS_FILE=$LOGS_FOLDER/$0.log

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [ $USERID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R Please run this script with root access $N" | tee -a $LOGS_FILE
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


dnf module disable nodejs -y &>>$LOGS_FILE
dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "enabled nodejs version 20 and get it ready for install"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS version 20"

id roboshop &>> $LOG_FILE
if [$? -ne 0]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "configure roboshop system user to run application as system user"
else
    echo -e "Roboshop user already created .... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

rm -rf /app &>>$LOGS_FILE
VALIDATE $? "remove existing code"

rm -rf /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "remove existing catalogue.zip"

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE 
cd /app 
unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Downloaded and extracted catalogue code"

npm install &>>$LOGS_FILE
VALIDATE $? "installing dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

cp mongodb.repo /etc/yum.repos.d/mongo.repo 
VALIDATE $? "Added Mongo repo"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installed MongoDB client"

INDEX=$(mongosh --host mongodb.daws90s.shop --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -lt 0 ]; then
    mongosh --host mongodb.daws90s.shop </app/db/master-data.js &>>$LOGS_FILE
    VALIDATE $? "Load Products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi
systemctl daemon-reload
systemctl enable catalogue
systemctl restart catalogue
systemctl restart catalogue

