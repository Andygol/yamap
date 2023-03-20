#!/bin/bash

DATA_DIR=/mnt/data
# export PG_PASSWORD=$POSTGRES_PASSWORD

# set option for running osmosis
# OSMOSIS tuning: 
# - https://wiki.openstreetmap.org/wiki/Osmosis/Tuning,
# - https://lists.openstreetmap.org/pipermail/talk/2012-October/064771.html

export JAVACMD_OPTIONS=" -server "

if [ ! -z "$MEMORY_JAVACMD_OPTIONS" ]; then
    JAVACMD_OPTIONS+=" -Xmx${MEMORY_JAVACMD_OPTIONS//i/} "
fi
    
data_file=$DATA_DIR/$(basename $URL_DATA_FILE_TO_IMPORT)
poly_file=$DATA_DIR/$(basename $URL_POLY_FILE_TO_IMPORT)

function downloadData () {
# check if files are in /mnt/data
# if data_file does not exist, download it
    if [ ! -f "$data_file" ]; then
        echo "$data_file dose not exist, downloading …"
        curl --output-dir $DATA_DIR -R -O $URL_DATA_FILE_TO_IMPORT
    fi

# if poly_file does not exist, download it
    if [ ! -f "$poly_file" ]; then
        echo "$poly_file dose not exist, downloading …"
        curl --output-dir $DATA_DIR -R -O $URL_POLY_FILE_TO_IMPORT
    fi
}

function populateData () {

    case "$1" in
        deploy)
            echo "Populanting $data_file into a fresh OSM API DB …"

            # https://wiki.openstreetmap.org/wiki/Osmosis#Notes on *.bz2 procession
            case "$data_file" in
                *.osm.pbf) osmosis_para=( osmosis --read-pbf-fast workers=4 file="$data_file" ) ;;
                *.osm.bz2) osmosis_para=( bzcat "$data_file" \| osmosis --fast-read-xml file=- ) ;;
                *) echo "There is nothing to populate into OSM API DB" ;;
            esac

            osmosis_para+=( --write-apidb )
            osmosis_para+=( host="$POSTGRES_HOST" )
            osmosis_para+=( database="$POSTGRES_DB" ) 
            osmosis_para+=( user="$POSTGRES_USER" )
            osmosis_para+=( password="$POSTGRES_PASSWORD" )
            osmosis_para+=( validateSchemaVersion=no )
            osmosis_para+=( allowIncorrectSchemaVersion=yes )

            echo -e "\nRunning ${osmosis_para[@]}\n"

            "${osmosis_para[@]}"
            ;;

        replication)
            while [ 1 -eq 1 ]; do 
    
                osmosis \
                --read-replication-interval workingDirectory=$DATA_DIR/replication_in \
                --simplify-change \
                --read-pbf file="$data_file" \
                --buffer \
                --apply-change \
                --bounding-polygon file="$poly_file" cascadingRelations=yes clipIncompleteEntities=true \
                --write-pbf file="$data_file".new

                if [ $? -eq 0 ]; then

                    echo -e "\nPouring data into the database\n"

                    osmosis \
                    --read-pbf file="$data_file.new" \
                    --read-pbf file="$data_file" \
                    --derive-change \
                    --write-apidb-change \
                        host="$POSTGRES_HOST" \
                        database="$POSTGRES_DB" \
                        user="$POSTGRES_USER" \
                        password="$POSTGRES_PASSWORD" \
                        validateSchemaVersion=no 

                    echo -e "\nreplacing $data_file\n"

                    mv "$data_file.new" "$data_file"
                    cp $DATA_DIR/replication_in/state.txt $DATA_DIR/replication_in/state.txt.bak

                else

                    echo -e "\nrestore state.txt from state.txt.bak\n"
                    cp $DATA_DIR/replication_in/state.txt.bak $DATA_DIR/replication_in/state.txt

                fi

            echo -e "\nwait 10 sec to continue...\n"

            sleep 10
            done 
            ;;

        dump) 
            osmosis \
            --read-apidb \
                host="$POSTGRES_HOST" \
                database="$POSTGRES_DB" \
                user="$POSTGRES_USER" \
                password="$POSTGRES_PASSWORD" \
                validateSchemaVersion=no \
            --buffer \
            --bounding-polygon \
                file="$poly_file" \
                completeRelations=yes \
                clipIncompleteEntities=true \
            --write-pbf file="$2"
            ;;
    esac

}

function replication () {

    # TODO hour/day adjustments    
    case $1 in
        miniute)    replication=( $replicationMinuteUrl $replicationMinuteMaxInterval ) ;;
        hour)       replication=( $replicationHourUrl $replicationHourMaxInterval ) ;;
        day)        replication=( $replicationDayUrl $replicationDayMaxInterval ) ;;
        "")         replication=( $replicationMinuteUrl $replicationMinuteMaxInterval ) ;;
    esac

    function replication_init () {

        echo -e "\nInitialization of replication\n"

        osmosis --read-replication-interval-init workingDirectory=$DATA_DIR/replication_in

        curl "https://replicate-sequences.osm.mazdermind.de/?$(date -u -d "@$(( $(stat -c "%Y" $data_file) - 3600 ))" +"%FT%TZ")" > $DATA_DIR/replication_in/state.txt
    }

    function replication_conf () {

        workingConfig=$DATA_DIR/replication_in/configuration.txt
        if [ ! -f $workingCongif ]; then
            echo "baseUrl=${replication[0]}" > $workingConfig
            echo "maxInterval=${replication[1]}" >> $workingConfig
        else
            sed -i -r "s,baseUrl=.*,baseUrl=${replication[0]},g" $workingConfig
            sed -i -r "s,maxInterval = .*,maxInterval = ${replication[1]},g" $workingConfig
        fi
    }

    if [ ! -d $DATA_DIR/replication_in ]; then
        mkdir -p $DATA_DIR/replication_in
    fi

    if [ ! -f $DATA_DIR/replication_in/state.txt ];then
        replication_init
    fi

    replication_conf
    
    populateData replication
}

# download data for further initial population into API DB

downloadData

case "$1" in

    init)       populateData deploy ;;
    replicate)  replication "$2" ;;
    dump)       populateData dump "$2" ;;
    *)          echo "Action is not specified"
                echo "Use $0 <param>"
                echo "  init                            for initial data deployment into a fresh DB"
                echo "  replicate [miniute|hour|day]    to keep up with upstream DB"
                echo "  dump <filename.osm.pbf>         to create *.osm.pbf from the local DB"
                exit 1 ;;

esac
