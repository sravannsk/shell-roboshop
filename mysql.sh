LOSG_FOLER=/var/log/roboshop
sudo mkdir -p $LOGS_FOLDER
chown -R  ec2-user:ec2-user $LOGS_FOLDER
chmod -R 755 $LOGS_FOLDER
LOGS_FILE=$LOGS_FOLDER/$0.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
USERID=$(id -u)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [$USERID -ne 0]; then
    echo -e "$TIMESTAMP [ERROR] $R Please run this script with root access $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE(){
    if [$1 -ne 0]; then
        echo -e "$TIMESTAMP [ERROR] $2 ... $R FAILURE $N | tee -a $LOG_FILE
    else
        echo -e "$TIMESTAMP [ERROR] $2 ... $G SUCCESS $N | tee -a $LOG_FILE
    fi
}

dnf install mysql-server -y &>> $LOGS_FILE
VALIDATE $? "Installing MYSQL Server"

systemctl enable mysqld &>> $LOG_FILE
systemctl start mysqld &>> $LOG_FILE
VALIDATE $? "Enable and start MySQL server"

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "setting up root password"
