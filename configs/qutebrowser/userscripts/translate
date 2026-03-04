#!/bin/bash

while [[ $# > 0 ]]; do
    case $1 in
        -s|--source)
            QUTE_TRANS_SOURCE=$2
            shift
            shift
            ;;
        -t|--target)
            QUTE_TRANS_TARGET=$2
            shift
            shift
            ;;
        --url)
            QUTE_TRANS_URL="true"
            shift
            ;;
        --text)
            QUTE_TRANS_URL="false"
            shift
            ;;
    esac
done

if [[ -z $QUTE_TRANS_SOURCE ]]; then
    # Default use automatic language for source
    QUTE_TRANS_SOURCE="auto"
fi
if [[ -z $QUTE_TRANS_TARGET ]]; then
    # Default use English for target
    QUTE_TRANS_TARGET="en"
fi

if [[ $QUTE_TRANS_URL == "false" ]]; then
    # Translate selected text
    PAGE="https://translate.google.com/#view=home&op=translate&"
    CONT_KEY="text"
    CONTENT=$QUTE_SELECTED_TEXT
else
    # Default translate URL
    PAGE="https://translate.google.com/translate?"
    CONT_KEY="u"
    CONTENT=$QUTE_URL
fi

echo "open -t ${PAGE}sl=$QUTE_TRANS_SOURCE&tl=$QUTE_TRANS_TARGET&$CONT_KEY=$CONTENT" >> "$QUTE_FIFO"
