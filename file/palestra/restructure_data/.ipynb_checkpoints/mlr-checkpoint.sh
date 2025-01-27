mlr --csv --ifs ";" \
    gsub -a '^ *$' '' \
    then rename -r '"^.+APPA.+$",COMUNI' \
    then put 'if(is_null(${COMUNI})){${COMUNI}="n"}else{${COMUNI}=${COMUNI}}' \
    then fill-down --all \
    then filter -x '$COMUNI=="n"' \
    elenco-unioni-comuni-comp.csv >elenco-unioni-comuni-comp_clean.csv
