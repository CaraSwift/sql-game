#!/bin/bash

# Database setup
DB_FILE="number_guess.sql"
TABLE_SETUP="CREATE TABLE IF NOT EXISTS users (
  username TEXT PRIMARY KEY,
  games_played INTEGER DEFAULT 0,
  best_game INTEGER DEFAULT 1000
);"

# Create database and table if not exists
sqlite3 $DB_FILE "$TABLE_SETUP"

# Prompt for username
read -p "Enter your username: " USERNAME

# Validate username length
if [ ${#USERNAME} -gt 22 ]; then
  echo "Error: Username must not exceed 22 characters."
  exit 1
fi

# Check if user exists
USER_INFO=$(sqlite3 $DB_FILE "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")

if [ -z "$USER_INFO" ]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  sqlite3 $DB_FILE "INSERT INTO users (username) VALUES ('$USERNAME');"
else
  GAMES_PLAYED=$(echo "$USER_INFO" | cut -d'|' -f1)
  BEST_GAME=$(echo "$USER_INFO" | cut -d'|' -f2)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate random number
SECRET_NUMBER=$((RANDOM % 1000 + 1))
GUESSES=0

echo "Guess the secret number between 1 and 1000:"

while true; do
  read -p "> " GUESS

  # Check if input is an integer
  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment guesses
  GUESSES=$((GUESSES + 1))

  # Compare guess with secret number
  if [ "$GUESS" -lt "$SECRET_NUMBER" ]; then
    echo "It's higher than that, guess again:"
  elif [ "$GUESS" -gt "$SECRET_NUMBER" ]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Update database
if [ -z "$USER_INFO" ] || [ "$GUESSES" -lt "$BEST_GAME" ]; then
  sqlite3 $DB_FILE "UPDATE users SET best_game=$GUESSES WHERE username='$USERNAME';"
fi
sqlite3 $DB_FILE "UPDATE users SET games_played=games_played+1 WHERE username='$USERNAME';"
