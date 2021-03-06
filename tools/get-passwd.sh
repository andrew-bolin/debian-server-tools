#!/bin/bash
#
# Obfuscated password input.
#
# VERSION       :0.2.0
# LOCATION      :/usr/local/bin/get-passwd-example.sh

Get_passwd() {
    local PROMPT="$1"
    local REAL_PASSWD="$2"

    local PASSWD=""
    local KEY=" "
    local DEL="$(echo -e "\x7F")"
    local LETTER_POS
    local LETTERS=(
        a b c d e f g h i j k l m n o p q r s t u v w x y z
        , . - _ = / % ! +
        A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        0 1 2 3 4 5 6 7 8 9
    )

    echo -n "$PROMPT"

    # Loop until ENTER is pressed
    while [ -n "$KEY" ]; do
        IFS="" read -s -n 1 KEY
        if [ "$KEY" == "$DEL" ]; then
            [ ${#PASSWD} -gt 0 ] && PASSWD="${PASSWD:0:(-1)}"
        else
            PASSWD+="$KEY"
        fi
        # Display a random character instead of $KEY
        LETTER_POS="$(( RANDOM * ${#LETTERS[*]} / 32768 ))"
        echo -n "${LETTERS[$LETTER_POS]}"
    done

    echo

    # Return value
    [ "$PASSWD" == "$REAL_PASSWD" ]
}

# Example
echo 'Type "alma"!'
Get_passwd "Pwd? " "alma" && echo "OK." || echo "Invalid pwd."
