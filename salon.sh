#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

# function to get requested service
SERVICES_MENU () {

  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # display menu
  echo "$($PSQL "SELECT * FROM services ORDER BY service_id")" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo -e "$SERVICE_ID) $SERVICE_NAME"
  done

  # get input
  read SERVICE_ID_SELECTED
  SERVICE_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")

  if [[ -z $SERVICE_SELECTED ]]
  then
    # if service doesn't exist, display services menu again
    SERVICES_MENU "\nI could not find that service. What would you like to do today?"
  else
    # otherwise, schedule appointment for requested service
    SCHEDULER "$SERVICE_ID_SELECTED"
  fi

}

# function to schedule appointments, which expects service_id as first argument
SCHEDULER () {
  
  # get name of requested service based on first argument
  SERVICE_ID_SELECTED=$1

  # if service doesn't exist, display services menu
  if [[ -z $SERVICE_ID_SELECTED ]]
  then
    SERVICES_MENU "\nI could not find that service. What would you like to do today?"
  fi

  # get customer info
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

  # if customer doesn't exist
  if [[ -z $CUSTOMER_ID ]]
  then
    # add & get customer info
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  else
    # otherwise, get customer name
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
  fi

  # get service time
  SERVICE_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
  echo -e "\nWhat time would you like your $(echo $SERVICE_SELECTED | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')?"
  read SERVICE_TIME

  # book the appointment
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
  if [[ $INSERT_APPOINTMENT_RESULT = "INSERT 0 1" ]]
  then
    # appointment successfully booked
    echo -e "\nI have put you down for a $(echo $SERVICE_SELECTED | sed -r 's/^ *| *$//g') at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g').\n"
  else
    echo -e "\nSomething went wrong, please try again later."
  fi
  
}

echo -e "\n~~~~~ MY SALON ~~~~~\n\nWelcome to My Salon, what would you like to do today?\n"

SERVICES_MENU
