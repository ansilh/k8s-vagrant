#!/usr/bin/env bash
# Create README and Vagrant files for every versions
# A new branch will be created with the name of k8s version (eg: v1.15.0)
#--- Logic -----
# READ VERSION FILE
# GET EACH WORD FROM VERSION FILE
# REPLACE THE WORD WITH THE VALUE
DEV_HEADER_MSG="may be in the middle of a change - use with caution"
PROD_HEADER_MSG=""
ICON_DEV=":fire:"
ICON_PROD=":white_check_mark:"

BRANCH=$(basename $(cat ../.git/HEAD|awk '{print $2}'))
if [ "${BRANCH}" == "development" ]
then
    ICON=${ICON_DEV}
    MSG=${DEV_HEADER_MSG}
else
    ICON=${ICON_PROD}
    MSG=${PROD_HEADER_MSG}
fi

echo ${BRANCH}
cp  README.template ../README.md
cp  Vagrantfile.template ../Vagrantfile
for LINE in $(cat ../scripts/VERSIONS)
do
    WORD=$(echo ${LINE}|awk -F "=" '{print $1}')
    VALUE=$(echo ${LINE}|awk -F "=" '{print $2}'|sed 's/"//g')
    if [ "${WORD}" == "BRANCH" ]
    then
        VALUE=$(basename $(cat ../.git/HEAD|awk '{print $2}'))
    fi
    sed -i "s/{{${WORD}}}/${VALUE}/g" ../README.md
    sed -i "s/{{${WORD}}}/${VALUE}/g" ../Vagrantfile
done
sed -i "s/{{MSG}}/${MSG}/g" ../README.md
sed -i "s/{{ICON}}/${ICON}/g" ../README.md
