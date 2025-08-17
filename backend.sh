#! /bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f 1)
TIME_STAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log"
mkdir -p $LOGS_FOLDER

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2  is... $R FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is.... $G successful $N" | tee -a $LOG_FILE
    fi
}

CHECK_ROOT_USER(){
    if [ $USERID -ne 0 ]; then
        echo -e "$R Pelease run this with root priveleges...$N" | tee -a $LOG_FILE
        exit 1
    fi
}


echo "Script started executing at $(date)" | tee -a $LOG_FILE
CHECK_ROOT_USER

dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disable default NodeJS module"
dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enable nodejs:20 module"
dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing NodeJS"

id expense &>> $LOG_FILE
if [ $? -ne 0 ]; then
    echo -e "Expense user not exist. Hence, $G Creating expense user.$N" | tee -a $LOG_FILE
    useradd expense &>> $LOG_FILE
    VALIDATE $? "Creating expense user"
else
    echo "expense user already exists. $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> $LOG_FILE
VALIDATE $? "Validating backend zip file download"

cd /app
unzip /tmp/backend.zip
VALIDATE $? "Unzipping backend files"

npm install &>> $LOG_FILE

##not giving pwd, since there is a possibilty of it alwasy different location currenlty, thats why have to give absolute path
cp /home/ec2-user/expense-shell-project/backend.service /etc/systemd/system/backend.service

# laod the data before running backend
dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "Installing MySql client"

mysql -h mysql.chaitu4d1.shop -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Loading schema"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl start backend
VALIDATE $? "Starting backend service"

systemctl enable backend
VALIDATE $? "Enabling backend service"
