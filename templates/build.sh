#!/usr/bin/env bash
# Create README and Vagrant files for every versions
# A new branch will be created with the name of k8s version (eg: v1.15.0)
#--- Logic -----
# READ VERSION FILE
# GET EACH WORD FROM VERSION FILE
# REPLACE THE WORD WITH THE VALUE
BRANCH=$(basename $(cat ../.git/HEAD|awk '{print $2}'))
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
