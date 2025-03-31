alias r="source $BASH_SOURCE"

flow-api() {
  declare path=$1
  : ${path:? required}

  [[ $DEBUG ]] && echo "---> [FLOW-API] /api/v1/${path}"
  [[ $TRACE ]] && set -x
  ${DRY:+echo [DRY]} curl -s \
    -H 'accept: application/json' \
    -b cookies.jar \
    -H "x-csrf-token: $(cat token.txt)" \
    -H 'user-agent: Mozilla/5.0' \
    -H 'referer: https://results.vertical-life.info/event/220/cr/2188' \
    https://results.vertical-life.info/api/v1/${path#/}
    set +x
}

flow-result() {
  flow-api category_rounds/2188/results \
  | tee results.json
}
ranks() {
  cat results.json \
   | jq -r '.ranking[]|"\(.rank)\t\(.score)\t\(.name)"'
}

update-html() {
  unzip -o FlowSeasons-2025-Spring.zip
  git add resources/ *.html 
  git commit -m "html updated"
  git push origin
  rm FlowSeasons-2025-Spring.zip
}

athlete-ids() {
  cat results.json \
  | jq -r '.startlist[].athlete_id' \
  | sort > athlete-ids.txt
}

all-athlete() {
  cat athlete-ids.txt \
  | while read id; do
    echo -n === ; 
    grep $id startlist.txt
    athlete ${id}
  done
  # clean small files
  # find . -name athlete\*.json -size -10 -delete
}

stat() {
  if ! [ -f stat.txt ] ; then
    for f in athlete-*.json; do
        cat $f | jq -r '.ascents[]|select(.top)|.route_name' 2>/dev/null \
        | tee -a stat.txt
    done
  else
    echo # === stat.txt is done ...
  fi

  cat stat.txt \
    | sort | uniq -c \
    | sed 's/ *\([0-9]\{1,3\}\) \([0-9]\{1,2\}\)/\2\t\1/' \
    | sort -n
}

jq-filter-sql() {
  cat <<'EOF'
    .athlete_id as $id 
  | .name as $name 
  | .ascents[]|select(.zone)
  | "insert into ascents VALUES ( '\($id)', '\($name)' , '\(.route_name)' , \(.zone) , \(.top) );"
EOF
}

jq-filter-txt() {
  cat <<'EOF'
    .athlete_id as $id 
  | .name as $name 
  | .ascents[]|select(.zone)
  | "\($id)\t\($name)\t\(.route_name)\t\(.zone)\t\(.top)"
EOF
}

create-raw-txt() {
  for f in athlete-*.json; do
    cat $f \
    | jq -r -f <(jq-filter-txt)
  done
}

create-raw-sql() {
  for f in athlete-${1:-*}.json; do
    cat $f \
    | jq -r -f <(jq-filter-sql)
  done
}

flow-sqlite() {
  rm -f flow.db
  sqlite3 flow.db < flow-schema.sql
  create-raw-sql \
  | tee flow-2025-sping.sql \
  | sqlite3 flow.db
}

zones() {
  sqlite3 flow.db -tabs <<EOF
    SELECT route_name,count(*) 
      FROM ascents 
      WHERE is_zone 
      GROUP BY  route_name 
      ORDER BY cast(route_name as INTEGER);
EOF
}
athlete() {
  declare id=$1
  : ${id:?reuired}

  if [ -f athlete-${id}.json ] && cat athlete-${id}.json | jq .ascents[].status | grep -q confirmed 2>/dev/null ; then
    echo === athlete: ${id} already done ...
  else 
    flow-api category_rounds/2188/athlete_details/${id} \
    | tee athlete-${id}.json \
    | jq -c '[.rank,.name,.score]'

    sleep ${SLEEP:-5}
  fi
}

startlist() {
  cat results.json \
   | jq -r '.startlist[]|"\(.athlete_id) \(.name)"'  \
   | fzf
}

startlist-txt() {
  cat results.json \
  | jq -r '.startlist[]|"\(.athlete_id) \(.name)"' \
  | sort \
  | tee startlist-by-id.txt

  cat results.json \
  | jq -r '.startlist[]|"\(.name) \(.athlete_id)"' \
  | sort \
  | tee startlist-by-name.txt
}
