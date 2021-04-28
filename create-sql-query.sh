#!/bin/bash

TODAY=$(date '+%Y-%m-%d')

function usage {
    echo "Usage: ./create-sql-query [OPTIONS] FILENAME"
    echo
    echo "  Create the SQL query to dump data in the same form as a cleaned CSV."
    echo
    echo "Options:"
    echo
    echo -e "  -d=DATE, --date=DATE\t\tUse given date (default: $TODAY)"
    echo -e "  -t=TABLE, --table=TABLE\t\tUse this SQL table name (default: rki_csv)"
    echo -e "  -h, --help\t\t\tShow this message and exit"
    exit
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d=*|--date=*)
        DATE="${key#*=}"
        shift
        ;;
        -t=*|--table=*)
        TABLE_NAME="${key#*=}"
        shift
        ;;
        -h|--help)
        usage
        shift
        ;;
        *)
        break
        ;;
    esac
done

if [[ $# -lt 1 ]]; then
    usage
fi

FILENAME=$1
REF_DATE=${DATE:-$TODAY}
TABLE=${TABLE_NAME:-'rki_csv'}

cat <<ENDMYSQL
SELECT
    'IdBundesland',
    'IdLandkreis',
    'Meldedatum',
    'Altersgruppe',
    'Geschlecht',
    'NeuerFall',
    'NeuerTodesfall',
    'NeuGenesen',
    'AnzahlFall',
    'AnzahlTodesfall',
    'AnzahlGenesen',
    'Refdatum',
    'IstErkrankungsbeginn',
    'Altersgruppe2',
    'GueltigAb',
    'GueltigBis',
    'DFID'
UNION ALL
SELECT
    IdBundesland,
    IdLandkreis,
    Meldedatum,
    Altersgruppe,
    Geschlecht,
    IF(NeuerFall = 1 AND GueltigAb < "$REF_DATE", 0, NeuerFall),
    IF(NeuerTodesfall = 1 AND GueltigAb < "$REF_DATE", 0, NeuerTodesfall),
    IF(NeuGenesen = 1 AND GueltigAb < "$REF_DATE", 0, NeuGenesen),
    AnzahlFall,
    AnzahlTodesfall,
    AnzahlGenesen,
    Refdatum,
    IstErkrankungsbeginn,
    Altersgruppe2,
    "$REF_DATE",
    NULL,
    DFID
FROM $TABLE
WHERE
    GueltigAb <= "$REF_DATE" AND
    (GueltigBis IS NULL OR "$REF_DATE" <= GueltigBis)
INTO OUTFILE '$FILENAME'
CHARACTER SET UTF8 FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';
ENDMYSQL