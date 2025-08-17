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

dnf install mysql-server -y &>> $LOG_FILE
VALIDATE $? "Installing MySql Server"
systemctl enable mysqld &>> $LOG_FILE
VALIDATE $? "Enabled MySql Server"
systemctl start mysqld &>> $LOG_FILE
VALIDATE $? "Started MySql Server"

mysql -h mysql.chaitu4d1.shop -u root -pExpenseApp@1 -e "show databases;" &>> $LOG_FILE
if [ $? -ne 0 ]; then
    echo -e "MYSQL root password is not set up, setting up now" &>> $LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "seting up root password"
else
    echo -e "MySql password is already set.... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

