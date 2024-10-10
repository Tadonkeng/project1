unset DEPENDS_ON_HASH 
declare -A DEPENDS_ON_HASH 



reconcile() {
    local dep=$1

    echo 'Fetching service dependencies. This will take a few seconds.'
    get_running_deployments
    get_all_dependencies "${ALL_DEPLOYMENTS[@]}"
    
    printf 'Each service with its dependency list.\n'
    for gkey in "${!DEPENDS_ON_HASH[@]}"; do 
      printf "    key: (%s) => Dependencies: (%s)\n" "$gkey" "${DEPENDS_ON_HASH[$gkey]}"
    done
    printf '\n\n'
    
    find_root_dependencies $dep
    build_dependency_list "${ROOT_DEPENDENCIES[@]}"

    printf 'Dependency list final version in ascending order.\n'
    printf '    M_DEPENDENCY_LIST = %s\n' "${M_DEPENDENCY_LIST[@]}"
    local input
    read -p "The above list of services will be stopped and restarted. Do you wish to continue? (Y/n) " input
    printf '\n\n'
   
    if [[ "$input" == "y" || "$input" == "Y" || "$input" == "yes" || "$input" == "Yes" ]] ; then 
    #Example of array that can be passed into reconcile_list
       #deployments=(argocd authservice cluster-auditor eck-operator ek fluent-bit gatekeeper istio istio-operator monitoring twistlock)
        echo 'NOTE--------  Beginning the suspend resume process.  THIS CAN HANG IF A SERVICE DOES NOT RECONCILE.  Ctrl C to stop. ----------'
        reconcile_list ${M_DEPENDENCY_LIST[@]}
    else
        echo 'exiting'
        exit 0
    fi
}


# find the namespace for a given name
find_namespace () {
    local name=$1
    #Get the name space from the flux command
    NAME_SPACE=`flux get hr -A | sed -n -e "/\t[ ]*$name[ ]*\t/p" | awk '{print $1}'`
    if [[ -z "$NAME_SPACE" ]]; then
      echo "Error: method find_namespace: no name space found for entry($name)"
      exit 1
    fi
}

#Suspend and resume a given deployment.  The name_space argument is optional.
suspend_resume () {
   local dep=$1 
   local name_space=$2
   if [[ -z "$name_space" ]]; then
     find_namespace $dep
     name_space=$NAME_SPACE
   fi
   echo "executing: flux suspend hr -n $name_space $dep"
   flux suspend hr -n $name_space $dep
   sleep 2
   echo "executing: flux resume hr -n $name_space $dep"
   flux resume hr -n $name_space $dep
}

#Suspend and resume each entry in the list.  The list is assumed to be in dependency order.
reconcile_list () {
   local list=("$@") 
   for entry in ${list[@]}; do
     #Entries in the list are stored as name:namespace
     IFS=':' read -r -a t1list <<< "$entry"
     local name="${t1list[0]}"
     local ns="${t1list[1]}"
     suspend_resume $name $ns
     watch_for_completion $name
   done
}

#wait for the entry to have a successful reconciliation. This can last forever if something goes wrong.
watch_for_completion () {
   local name=$1
   local success
   echo "Watching for reconciliation of $name"
   flux get hr -A 
   printf "\n\n"
   local ct=0
   while [[ -z "$success" ]] ; do
     success=`flux get hr -A | sed -n "/\t[ ]*$name[ ]*\t/p" | grep "succeeded"`
     if [[ -z "$success" ]]; then
       echo "Watching for reconciliation of $name"
       flux get hr -A 
       printf "\n\n"
       sleep 5
     fi
     ct=$[$ct + 1]
     #TODO something if it has been to long
   done
}



get_running_deployments() {
   #global variable storing all the deployments. 
   unset ALL_DEPLOYMENTS
   ALL_DEPLOYMENTS=()

   #Get all the depooyments from flux
   local tmp=`flux get hr -A | egrep -v "NAMESPACE|REVISION" | awk '{print $2":"$1'}`
   #remove newline
   tmp=`echo $tmp | sed 's/\n//g'`

   if [[ -z "$tmp" ]]; then
     echo "Error get_running_containers:  No running services found."
     exit 1
   fi
   #Put all the deployments into an array splitting the data on the space charaacter
   IFS=' ' read -r -a ALL_DEPLOYMENTS <<< "$tmp"
}

#Given a list find all dependicies for the entries in it.
get_all_dependencies() {
   local dep_list=("$@") 
   if [[ -z "$dep_list" ]]; then
     echo "Error get_all_dependencies:  No dependencies were passed in."
     exit 1
   fi
   for t in "${dep_list[@]}"; do
     #Entries in the list are stored as name:namespace
     IFS=':' read -r -a t1list <<< "$t"
     local name="${t1list[0]}"
     local ns="${t1list[1]}"
     get_dependencies $name $ns
   done
}


#Get all the deployments that depend on this deployment.  The name_space arg is optional
get_dependencies() {
   local name=$1
   local name_space=$2
   if [[ -z "$name_space" ]]; then
     find_namespace $name
     name_space=$NAME_SPACE
   fi

   if [[ -z "$name" || -z "$name_space" ]]; then
       echo "Error:  Dependency($name) or name_space($name_space) was not set."
       exit 1
   fi

   local key="$name:$name_space"
   #Get the dependicies from kubectl in json format
   local data=`kubectl get hr -n $name_space $name -o json`
   if [[ -z "$data" ]];  then
       echo "Error: No data returned for command \"kubectl get hr -n $name_space $name -o json | jq -c .spec.dependsOn\" could not determine dependencies."
       exit 1
   fi

   data=`echo $data | jq -c .spec.dependsOn`
   #Some deployments will have no dependecies.  That is fine we can exit the function.
   if [[ -z "$data" || "$data" = "null" ]]; then
      DEPENDS_ON_HASH[$key]=""
      return
   fi

   data=`echo $data | jq -c '.[]'`
   #Loop through all the dependecies
   for row in $data; do
     local name=`echo ${row} | jq -r '.name'`
     local ns=`echo ${row} | jq -r '.namespace'`
     local value="$name:$ns,"
     #Add dependency to the comma seperated list.  Data format is "name:namespace,name:namespace,..."
     DEPENDS_ON_HASH[$key]+=$value
   done

   #If we had any dependencies strip the trailing comma from the list.
   if [[ -n  DEPENDS_ON_HASH[$key] ]]; then
     local tmp=${DEPENDS_ON_HASH[$key]}
     tmp=${tmp::-1}
     DEPENDS_ON_HASH[$key]=$tmp
   fi
}

#Find the deployments that have no dependencies or if a deployment name is passed in just use it as the root dependecy.
find_root_dependencies () {
   local dep=$1
   #Global variable
   unset ROOT_DEPENDENCIES
   ROOT_DEPENDENCIES=()

   #If a deployment was passed in use it as the root deployment
   if [[ -n "$dep" ]]; then
     IFS=':' read -r -a t1list <<< "$dep"
     local name="${t1list[0]}"
     local ns="${t1list[1]}"
     if [[ -z "$ns" ]];then
       find_namespace $dep
       ns=$NAME_SPACE
     fi
     #the ";0" is the index of the entry and it signifies at what level it should be reconciled.  0 means first, 1 second, etc.
     local entry="$name:$ns;0"
     ROOT_DEPENDENCIES+=($entry)
     return
   fi

   #Loop through all deployments and find the ones with no dependencies.
   for key in ${!DEPENDS_ON_HASH[@]}; do
       local value=${DEPENDS_ON_HASH[$key]}
       if [[ -z "$value" ]]; then
          #the ";0" is the index of the entry and it signifies at what level it should be reconciled.  0 means first, 1 second, etc.
          local entry="$key;0"
          ROOT_DEPENDENCIES+=($entry)
       fi
   done
}



#Given a list of deployments find all deployments that depend on them.
build_dependency_list () {
   #Global variable.  Used to build the master dependenciy list. Keeps track of deploments that have been accounted for.
   unset USED_DEPENDENCIES
   declare -A USED_DEPENDENCIES
   #Global variable.  Master dependenciy list.
   unset M_DEPENDENCY_LIST
   M_DEPENDENCY_LIST=()

   #The list of dependencies
   local dep_list=("$@") 
   if [[ -z "$dep_list" || ${#dep_list[@]} -eq 0 ]]; then
      echo "Error: build_dependency_list:  input array is empty"
      exit 1
   fi

   #Add the deployments that were passed in to the maseter list. 
   M_DEPENDENCY_LIST+=(${dep_list[@]})
   for entry in "${dep_list[@]}"; do
      IFS=';' read -r -a t1list <<< "$entry"
      local key=${t1list[0]}
      local index=${t1list[1]}
      #Add the deployment to list so we know we can ignore them from now on
      USED_DEPENDENCIES[$entry]=$key
   done


   local success=true
   #Loop while we keep finding new dependencies.
   while [[ "$success" = true ]] ; do
      success=false
      local tmpList=()
      #Loop through the deployments
      for entry in "${M_DEPENDENCY_LIST[@]}"; do
         IFS=';' read -r -a t1list <<< "$entry"
         local key=${t1list[0]}
         local index=${t1list[1]}

         #Find deployments that are dependent on this deployment
         lookup_dependencies $key 
      
         #If we found any dependent deployments add them to the temporyList.  Use a tempory list because we are looping over the master list and we don't want to modify it while looping though it.
         if [[ -n "$DEPENDENCY_LIST" && ${#DEPENDENCY_LIST[@]} -ne 0 ]]; then
           tmpList+=(${DEPENDENCY_LIST[@]})
         fi
      done

      #If we found any dependent deployments add them to the master list and set succuss to true because we need to search again.
      if [[ -n "$tmpList" && ${#tmpList[@]} -ne 0 ]]; then
        M_DEPENDENCY_LIST+=(${tmpList[@]})
        success=true
      fi
   done
   
printf 'Dependency list before assigning level\n'
printf '    M_DEPENDENCY_LIST = %s\n' "${M_DEPENDENCY_LIST[@]}"
printf '\n\n'

   local upindex=true
   local current_index=0
   #Now loop through all the deployments that need to be reconciled and determine the order they should be done in.
   while [[ "$upindex" = true ]] ; do
     upindex=false
     local next_index=$[$current_index + 1]
     for e2 in ${M_DEPENDENCY_LIST[@]}; do
       IFS=';' read -r -a t1list <<< "$e2"
       local key1=${t1list[0]}
       local index1=${t1list[1]}

       #We only want to look at the current level e.g. index = current_index.
       #We start at level zero and as we progress we never need to go back.
       #We move deployments from the current level to the next if they have dependices in the current level.
       if [[ "$index1" != "$current_index" ]]; then
         continue
       fi
       #Loop through all deployments checking if any have dependencies on the current one e.g. key1
       for i1 in ${!M_DEPENDENCY_LIST[@]}; do
         local e3="${M_DEPENDENCY_LIST[$i1]}"
         IFS=';' read -r -a t2list <<< "$e3"
         local key2=${t2list[0]}
         local index2=${t2list[1]}

         #If the two deployments are the same or this deployment is not on the correct level skip it.
         if [[ "$key1" = "$key2" || "$index2" != "$current_index" ]]; then
             continue
         fi

         #Get the dependenciy list for deployment 2.
         local value=${DEPENDS_ON_HASH[$key2]}
         #Does the dependency list contain deployment1.  If so increment the level of deployment 2. Also set upindex so we know we are not done yet.
         if [[ "$value" =~ .*"$key1".* ]]; then
           upindex=true
           local tentry="$key2;$next_index"
           M_DEPENDENCY_LIST[$i1]="$tentry"
         fi
       done
     done
     #Move to the next level
     current_index=$next_index
   done

printf 'Dependency list with level assigned\n'
printf '    M_DEPENDENCY_LIST = %s\n' "${M_DEPENDENCY_LIST[@]}"
printf '\n\n'

   #Build the final list of deployments in correct order but without the level indices.
   success=true
   current_index=0
   #Save off the master list and reset the master list so we can rebuild it.
   local tmpList=(${M_DEPENDENCY_LIST[@]})
   unset M_DEPENDENCY_LIST
   M_DEPENDENCY_LIST=()

   #While we are still adding deployments to the list.  Start at level one and increase the level on each iteration.
   while [[ "$success" = true ]] ; do
     success=false
     #Loop through the list.
     for e2 in ${tmpList[@]}; do
       IFS=';' read -r -a t1list <<< "$e2"
       local key1=${t1list[0]}
       local index=${t1list[1]}
       #If the deployment is not at the current level skip it
       if [[ "$index" != "$current_index" ]]; then
         continue
       fi
       #This deployment is on the current level so add it to the list.
       success=true
       M_DEPENDENCY_LIST+=($key1) 
     done
     current_index=$[$current_index + 1]
  done
}

#
lookup_dependencies () {
   #Global variable used to store the dependencies found here
   unset DEPENDENCY_LIST
   DEPENDENCY_LIST=()

   #The deployment passed in that.  Search for its dependencies.
   local dep=$1 
   if [[ -z "$dep" ]]; then
      echo "Error: no argument passed into lookup_dependencies"
      exit 1
   fi

   #Loop through all the deployments
   for key in ${!DEPENDS_ON_HASH[@]}; do
     #skip if this deployment is the one that was passed in
     if [[ $key == $dep ]]; then
       continue
     fi

     #Get the list of dependencies
     local value=${DEPENDS_ON_HASH[$key]}
     #If the deployment is in the list of dependencies add it.
     if [[ "$value" =~ .*"$dep".* ]]; then
       upindex=true
       #If we have not added it already then add it.
       if [[ -z "${USED_DEPENDENCIES[$key]}" ]]; then
          local entry="$key;0"
          USED_DEPENDENCIES[$key]=$key
          DEPENDENCY_LIST+=("$entry")
       fi
     fi
   done
}


