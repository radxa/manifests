#!/bin/bash
MANIFEST_PATH=./default.xml
project_name=`~/bin/read_manifest -i $MANIFEST_PATH --project $1 --key name`
echo "    <remove-project name=\"$project_name\"/>" >> ./remove_s.xml
#echo "---"
#echo "<remove-project name=\"$1\"/>"
project_path=`~/bin/read_manifest -i $MANIFEST_PATH --project $1 --key path`
project_revision="rk35/mid/12.0/develop"
echo "    <project name=\"$project_name\" path=\"$project_path\" revision=\"$project_revision\"/>" >> include/rk_checkout_repository.xml
