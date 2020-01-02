#------------------------------------------------------------------------------#
# This file contains all public function defenitions                           #
#------------------------------------------------------------------------------#


#------------------------------------------------------------------------------#
# This function 'adjust_spec_version' will take input YAML file name as        #
# command line argument and normalize it according to the available apiVersion #
# of the k8s cluster                                                           #
# Author : Ansil H                                                             #
# Email: ansilh@gmail.com                                                      #
# Date: 01/03/2020                                                             #
#------------------------------------------------------------------------------#
adjust_spec_version(){

        INPUT_ORIGINAL=${1}
        # Check whether yq_linux_amd64 exists or not
        if [ ! -e ./yq_linux_amd64 ]
        then
                echo "ERROR: yq_linux_amd64 is not present"
                return 253
        fi

        # If file is already processed , then exit without touching back-up file
        if [ ! -f ${INPUT_ORIGINAL}_bkp ]
        then
                # Take a backup before processing file
                cp -p ${INPUT_ORIGINAL} ${INPUT_ORIGINAL}_bkp
        else
                echo "ERROR:${INPUT_ORIGINAL} already normalized"
                return 255
        fi

        i=0;
        OUTPUT=$$

        # Loop through the input file and extract each YAML document and adjust API version \
        #  according to the deployed k8s version
        until ! (./yq_linux_amd64 read -d${i} ${INPUT_ORIGINAL} apiVersion 1>/dev/null 2>&1);
        do
                # Yaml separator
                echo "---" >>${OUTPUT}

                # Extract one YAML document
                ./yq_linux_amd64 read -d${i} ${INPUT_ORIGINAL} >>${OUTPUT}

                # Retrieve apiVersion from document
                API_VERSION=$(./yq_linux_amd64 read -d${i} ${OUTPUT} apiVersion);

                # Retrieve kind from document
                KIND=$(./yq_linux_amd64 read -d${i} ${OUTPUT} kind)

                # Increase document count to extract next document from input file
                i=`expr $i + 1`

                # echo "${API_VERSION}|${KIND}"
                # Check the existance of Kind
                kubectl explain ${KIND} 1>/dev/null 2>&1
                if [ $? -ne 0 ]
                then
                        echo "Kind ${KIND} is not available"
                        rm ${INPUT_ORIGINAL}_bkp
                        rm ${OUTPUT}
                        return 254
                fi

                # Get the available apiVersion using the kind on deployed k8s version
                NEW_API_VERSION=$(kubectl explain ${KIND} |grep VERSION |awk '{print $2}')

                # Replace apiVersion in YAML document with the available apiVersion
                sed -i "s@apiVersion: ${API_VERSION}@apiVersion: ${NEW_API_VERSION}@" ${OUTPUT}
        done
        #sed -i "$d" ${OUTPUT}
        # Replace input YAML with newly generated YAML file
        mv ${OUTPUT} ${INPUT_ORIGINAL}
}
