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

dnf install nginx -y  &>> $LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>> $LOG_FILE
VALIDATE $? "Enabling Nginx"

systemctl start nginx &>> $LOG_FILE
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
VALIDATE $? "Removing default Nginx Website files"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>> $LOG_FILE
VALIDATE $? "Downloading frontend zip code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>> $LOG_FILE
VALIDATE $? "Unzipping frontend files"

systemctl restart nginx &>> $LOG_FILE
VALIDATE $? "Restarting Nginx"