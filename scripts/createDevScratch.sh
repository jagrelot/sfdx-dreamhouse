#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATH_TO_DATA_FOLDER=$CURRENT_DIR/../config/data
PATH_TO_DATA_PLAN_FILE=$PATH_TO_DATA_FOLDER/DataPlan.json
PATH_TO_USER_FOLDER=$CURRENT_DIR/../config/users
SCRIPT_FUNCTION_FILE=$CURRENT_DIR/scriptFunctions.sh
source $SCRIPT_FUNCTION_FILE

echo
while [ ! $# -eq 0 ]
do
    case "$1" in
        --help | -h)
            echo
            echo "   --story-number | -s"
            echo "       Specify the user story you will be developing in this scratch org. This will also be the alias for your Scratch org and the name of the git feature branch."
            echo
            echo "   --git-branch | -g"
            echo "       Specify the name of your git branch you would like to use to create your scratch org."
            echo
            echo "   --org-def-file | -o"
            echo "        Specify the path to the Organization definition file you would like to use to create your scratch org"
            echo
            exit
            ;;
        --story-number | -s)
            storyNumber=$2
            echo Story number is $storyNumber
            ;;
        --git-branch | -g)
            gitBranch=$2
            echo Git branch is $gitBranch
            ;;
        --org-def-file | -o)
            orgDefinitionFile=$2
            echo org definition file is $orgDefinitionFile
    esac
    shift
done

echo Creating your dev Scratch org
echo

checkout_git_branch "$gitBranch"

create_git_branch "$storyNumber"

create_scratch_org_with_definition_file_and_story_name "$orgDefinitionFile" "$storyNumber"

create_pws

push_source_to_scratch_org

generate_permission_for_base_user

create_users_from_user_folder "$PATH_TO_USER_FOLDER" "$storyNumber"

#import_to_scratch_org_from_data_folder "$PATH_TO_DATA_FOLDER"

import_data_from_data_plan_file "$PATH_TO_DATA_PLAN_FILE"

open_scratch_org "$storyNumber"
