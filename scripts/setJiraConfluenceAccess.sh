#!/bin/bash
##########################################################################################################
# Script Name: 
# Description: This script will assign attribute values based on groups users are assigned to in keycloak.
#              Under the Atlassian parent group.
#              
# Args       : None
# Author     : Jason Crothers
# Version    : 1.0.0
# Notes      : You must ensure the keycloak groups are created in all lower case.
#              Also, must ensure that the keycloak secret "keycloak-credentials" exists.
#              One last thing to ensure is keycloak var is correct FQDN of keycloak.
#              .....
#              .....
##########################################################################################################
##########################################################################################################
# Begin Variables
##########################################################################################################
#Ansi colors
green="\e[0;92m"
red="\e[0;91m"
reset="\e[0m"
yellow="\e[0;93m"
#Keycloak vars
keycloakUserID=$(kubectl get secrets -n keycloak keycloak-credentials -o jsonpath='{.data.adminuser}'| base64 -d)
keycloakUserPW=$(kubectl get secrets -n keycloak keycloak-credentials -o jsonpath='{.data.password}'| base64 -d)
keycloakFQDN="keycloak.mgmt.prod.uc2s.dsop.io"
log=/var/log/jira_confluence_access_log.txt
today=$(date +"%Y-%m-%d-%H.%M.%S-%Z")
##########################################################################################################
# End Variables
##########################################################################################################

##########################################################################################################
# Begin Functions
##########################################################################################################
getAuthToken () {
    token=$(curl -k -s -X POST \
    -H "Content-Type:application/x-www-form-urlencoded" \
    -d "username=${keycloakUserID}" \
    -d "password=${keycloakUserPW}" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" \
    "https://${keycloakFQDN}/auth/realms/master/protocol/openid-connect/token" \
    |awk -F '"' '{print $4}')

    if [[ ${token} == ${null} ]]; then
        echo -e "${red}${today} - Wasn't able to authenticate with keycloak and get the token.${reset}" >> ${log}
        exit 1
    fi
}

getAllGroups () {
    getGroups=$(curl -k -s -X GET \
    -H "Content-Type:application/json" \
    -H "Authorization:Bearer ${token}" \
    "https://${keycloakFQDN}/auth/admin/realms/baby-yoda/groups")

    if [[ ${getGroups} == ${null} ]]; then
        echo -e "${red}${today} - Wasn't able to get groups from keycloak.${reset}" >> ${log}
        exit 1
    fi
}

getGroupIDs () {
    #Set IFS to newline field seperator
    OIFS=$IFS
    IFS=$'\n'
    # Create jira group array from the getGroups var
    # jiraGroupsArray will be in the following format:
    # <KEYCLOAK_GROUP_ID>:<JIRA_GROUP_NAME>:<KEYCLOAK_GROUP_PATH>
    jiraGroupsArray=( $(echo "${getGroups}"|tr -d '[]}"'|tr '{' '\n'|awk 'NF'|awk -F '[:,]' '{print $2":"tolower($4)":"$6}'|grep -i jira) )
    confluenceGroupsArray=( $(echo "${getGroups}"|tr -d '[]}"'|tr '{' '\n'|awk 'NF'|awk -F '[:,]' '{print $2":"tolower($4)":"$6}'|grep -i confluence) )

    # Check jiraGroupsArray for parent jira group
    # If a parent jira group doesn't exist exit script
    for i in ${jiraGroupsArray} ${confluenceGroupsArray}; do
        if [[ ${i} == ${null} ]]; then
            clear
            echo -e "${yellow}${today} - Something may have went wrong, the ${i} is equal to null. Check to see if groups exist in Keyclaok.${reset}" >> ${log}
            IFS=$OIFS
            exit 1
        fi
    done
    IFS=$OIFS
}

getMemberUpdates () {
    OIFS=$IFS
    IFS=$'\n'
    # Loop through subGroupArray and seperate Keycloak group ID and Keycloak sub group name into seperate vars
    #
    # Loop through subGroupArray and retrieve all members of each subgroup
    # 
    for i in ${jiraGroupsArray[@]} ${confluenceGroupsArray[@]}; do
        subGroupID=$(echo $i|awk -F ':' '{print $1}')
        subGroupName=$(echo $i|awk -F ':' '{print $2}')
        #Curl Keycloak to get all Members of sub group
        getAuthToken
        getMembers=$(curl -k -s -X GET \
        -H "Content-Type:application/json" \
        -H "Authorization:Bearer ${token}" \
        "https://${keycloakFQDN}/auth/admin/realms/baby-yoda/groups/${subGroupID}/members")

        #Check to see if members exist in group
        if [[ "${getMembers}" != "[]" ]]; then
            # Format getMembers by removing [{ from the begining of the first user id string
            getMembers=$(sed 's/\[{//' <<< ${getMembers})
            # Format getMembers by removing }] from the end of the last user id string
            getMembers=$(sed 's/}\]//' <<< ${getMembers})
            # Format getMembers var by adding a return at the end of individual data
            getMembers=$(sed 's/},{/\n/g' <<< ${getMembers})

            # Determine whether to use jira-groups or confluence-groups attribute name
            echo "${i}"|grep -i jira &> /dev/null
            if [[ $? -eq 0 ]]; then
                attributeGroupName='"jira-groups"'
            else
                attributeGroupName='"confluence-groups"'
            fi

            # Create member ID array
            rawMemberArray=( $(echo "${getMembers}") )
            for j in ${rawMemberArray[@]}; do
                updateUser="no"
                # Get UserID only
                userID=$(echo "${j}"|awk -F '"' '{print $4}')
                # Get raw user attributes
                rawAttributes=$(echo "${j}"|awk -F '"attributes":{' '{print $2}'|awk -F '}' '{print $1}'|sed 's/],/]|/g')
                # Remove [] from raw attributes and create attributes array
                #attributesArray=( $(echo ${rawAttributes}|tr -d '['|sed 's/],/\n/g'|tr -d ']') )
                attributesArray=( $(echo ${rawAttributes}|sed 's/|/\n/g') )
                attributesArrayLength=$(echo "${#attributesArray[@]}")
                # Check to see if user exists inside of updateAttributeArray
                # If the user exists inside the updateAttrributeArray, update the attributesArray
                # with these attributes instead.
                for n in ${updateAttributesArray[@]}; do
                    uID=$(echo "${n}"|awk -F '"' '{print $4}')
                    if [[ "${userID}"  == "${uID}" ]]; then
                        attributesArray=( $(echo ${n}|sed 's/],/]|/g'|sed 's/|/\n/g') )
                        attributesArrayLength=$(echo "${#attributesArray[@]}")
                        break
                    fi
                done

                w=0
                x=0
                for k in ${attributesArray[@]}; do
                    attributeName=$(echo $k|awk -F ':' '{print $1}')
                    if [[ ${attributeName} != ${attributeGroupName} ]]; then
                        x=$((x+1))
                    fi

                    if [[ ${attributeName} == ${attributeGroupName} ]]; then
                        attributeValue=$(echo $k|awk -F ':' '{print $2}')
                        #Create a temp array to hold all values individually
                        attributeValueArray=( $(echo ${attributeValue}|tr -d '"[]'|tr ',' '\n') )
                        #Check to see if sub group name exists in user attribute value
                        #If it doesn't exist add it to the attribute value                        
                        attributeValueArrayLength=$(echo "${#attributeValueArray[@]}")
                        y=0
                        for l in ${attributeValueArray[@]}; do
                            if [[ ${l} != ${subGroupName} ]]; then
                                y=$((y+1))
                            fi
                        done
                        if [[ ${attributeValueArrayLength} -eq ${y} ]]; then
                            #Add sub group name to the temp value array
                            attributeValueArray[${y}]=${subGroupName}
                            #Create new tempAttribute with new values
                            z=0
                            for m in ${attributeValueArray[@]}; do
                                if [[ ${z} -eq 0 ]]; then
                                    newAttributeValue="\"$m\""
                                    z=$((z+1))
                                else
                                    newAttributeValue+=",\"$m\""
                                fi
                            done
                            #Add subGroupName to userDataArray
                            attributesArray[${w}]="${attributeName}:[${newAttributeValue}]"
                            updateUser="yes"
                        fi
                        break
                    fi
                    w=$((w+1))
                done
                
                #Add jira-groups attribute and subGroupName
                if [[ ${x} -eq ${attributesArrayLength} ]]; then
                    #Update attributeArray with jira-groups and subGroupName
                    attributesArray[${x}]="${attributeGroupName}:[\"${subGroupName}\"]"
                    updateUser="yes"
                fi

                #Update jira-groups attribute with subGroupName
                if [[ ${updateUser} == "yes" ]]; then
                    a=0
                    for m in ${attributesArray[@]}; do
                        if [[ ${a} -eq 0 ]]; then
                            userAttributes="${m}"
                            a=$((a+1))
                        else
                            userAttributes+=",${m}"
                        fi
                    done
                    #Add User to updateAttributesArray
                    updateAttributesArrayLength=$(echo "${#updateAttributesArray[@]}")
                    b=0
                    if [[ ${updateAttributesArrayLength} -eq 0 ]]; then
                        updateAttributesArray[${b}]="\"id\":[\"${userID}\"],${userAttributes}"
                    fi
                    if [[ ${updateAttributesArrayLength} -gt 0 ]]; then
                        for i in ${updateAttributesArray[@]}; do
                            uID=$(echo "${i}"|awk -F '"' '{print $4}')
                            if [[ "${userID}"  != "${uID}" ]]; then
                                b=$((b+1))
                            fi
                            if [[ "${userID}"  == "${uID}" ]]; then
                                updateAttributesArray[${b}]="${userAttributes}"
                                break
                            fi
                        done
                    fi
                    if [[ ${b} -eq ${updateAttributesArrayLength} ]]; then
                        updateAttributesArray[${b}]="\"id\":[\"${userID}\"],${userAttributes}"
                    fi 
                fi
            done
        fi # Query the next group in the Array     
    done
    IFS=$OIFS
}

updateUserAttributes () {
    OIFS=$IFS
    IFS=$'\n'
    getAuthToken
    for i in ${updateAttributesArray[@]}; do
        userID=$(echo "${i}"|awk -F '"' '{print $4}')
        attributes=$(echo "${i}"|cut -d ',' -f2-)
        rv=$(curl -i -s -X PUT \
        -H "Content-Type:application/json" \
        -H "Authorization:Bearer ${token}" \
        -d \
        "{\"attributes\":{${attributes}}}" \
        "https://${keycloakFQDN}/auth/admin/realms/baby-yoda/users/${userID}"|head -1|awk '{print $2}')

        if [[ "${rv}" != 204 ]]; then
            echo -e "${red}${today} - Wasn't able to update the following user: ${userID}${reset}" >> ${log}
        fi
        if [[ "${rv}" == 204 ]]; then
            echo -e "${green}${today} - Updated the following user: ${userID}${reset}" >> ${log}
        fi
    done
    IFS=$OIFS
}
##########################################################################################################
# End Functions
##########################################################################################################

##########################################################################################################
# Begin Main
##########################################################################################################
getAuthToken
getAllGroups
getGroupIDs
getMemberUpdates
updateUserAttributes
##########################################################################################################
# End Main
##########################################################################################################
