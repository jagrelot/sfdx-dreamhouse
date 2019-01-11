BASE_USER_PERMISSION="Privacy_Base"
SFDX_PATH="/usr/local/bin/" 

function checkout_git_branch() {
    # git checkout origin/privacy
    local branch_to_checkout=$1
    echo checking out git branch $branch_to_checkout...
    echo
    git checkout $branch_to_checkout
    echo
    echo checked out branch
    echo
}

function create_git_branch() {
    # branch feature branch using ISO-####
    local branch_to_create=$1
    local branch_to_branch_from=$2
    echo creating and checking out branch $branch_to_create...
    echo
    git checkout -b $branch_to_create $branch_to_branch_from
    echo
    echo created branch
    echo
    git push $branch_to_branch_from
}

function create_scratch_org_with_definition_file_and_story_name() {
    # sfdx force:org:create -f config/orgs/privacy-scratch-def.json -a ISO-####

    local org_definition_file=$1
    local story_number=$2
    echo creating scratch org...
    echo
    $SFDX_PATH/sfdx force:org:create -f $org_definition_file -a $story_number -s -d 16
    if [ $? -eq 0 ]; then
        echo created scratch org
        echo
    else
        #exit script if creating failed so other orgs aren't affected
        echo "failed to create scratch org"
        echo "exiting script"
        exit
    fi
}

function push_source_to_scratch_org() {

    #echo Pushing checked out source
    #sfdx force:source:push -u $storyNumber
    #echo Pushed checked out source
    #echo

    local org_alias=$1
    echo pushing source ...
    echo
    if [ -z "$org_alias" ]
    then
        $SFDX_PATH/sfdx force:source:push
    else
        $SFDX_PATH/sfdx force:source:push -u $org_alias
    fi
    echo
    echo pushed source
    echo
}

function create_users_from_user_folder() {
    # sfdx force:user:create -f config/users/compliance-staff-def.json
    echo "generating users from user folder..."
    echo
    local user_folder=$1
    local story_number=$2
    
    for file in $(find $user_folder -name '*.json'); 
        do create_user_from_definition_file "$file" "$story_number";
    done
}

function create_user_from_definition_file() {
    local definition_file=$1
    local story_number=$2

    $SFDX_PATH/sfdx force:user:create -f $definition_file
    echo

}

function create_pws() {
    # sfdx create pws
    echo
    echo "generating password..."
    echo
    sfdx force:user:password:generate 
    echo
}

function generate_permission_for_base_user() {
    echo
    echo "Assigning $BASE_USER_PERMISSION permission for user"
    echo
    sfdx force:user:permset:assign -n $BASE_USER_PERMISSION
    echo
}

function import_to_scratch_org_from_data_folder() {
    # sfdx force:data:import
    local data_folder=$1
    echo importing data...
    echo
    for file in $(find $data_folder -name '*.json'); 
        do echo "sfdx force:data:tree:import --sobjecttreefiles $file"; 
    done
}

function import_data_from_data_plan_file() {
    local data_plan_file=$1
    echo importing data...
    echo
    $SFDX_PATH/sfdx force:data:tree:import -p $data_plan_file
    echo
}

function open_scratch_org() {
    echo Logging in
    #sfdx force:org:open -u $storyNumber
    local org_alias="$1"
    if [ -z "$org_alias" ]
    then
        $SFDX_PATH/sfdx force:org:open
    else
        $SFDX_PATH/sfdx force:org:open -u $org_alias
    fi
}