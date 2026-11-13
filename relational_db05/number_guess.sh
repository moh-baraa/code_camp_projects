#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# توليد رقم عشوائي بين 1 و 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read USERNAME

# التحقق مما إذا كان المستخدم موجوداً في قاعدة البيانات
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")

if [[ -z $USER_ID ]]
then
  # إضافة المستخدم إذا لم يكن موجوداً
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL);")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # جلب إحصائيات المستخدم القديم
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME';")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME';")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo "Guess the secret number between 1 and 1000:"
read GUESS

NUMBER_OF_GUESSES=1

# حلقة التخمين
while [[ $GUESS != $SECRET_NUMBER ]]
do
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
  
  read GUESS
  ((NUMBER_OF_GUESSES++))
done

# جلب بيانات المستخدم لتحديثها
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")
GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME';")
BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME';")

NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))

# تحديث أفضل نتيجة (Best Game) إذا كانت أقل أو إذا كانت اللعبة الأولى
if [[ -z $BEST_GAME || $BEST_GAME == "" || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
then
  UPDATE_STATS=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$NUMBER_OF_GUESSES WHERE user_id=$USER_ID;")
else
  UPDATE_STATS=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED WHERE user_id=$USER_ID;")
fi

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"