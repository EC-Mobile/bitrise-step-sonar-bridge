#!/bin/bash
set -ex

# check platform
lowercase_platform=$( tr '[:upper:]' '[:lower:]' <<<"$platform" )
case $lowercase_platform in
  ios)
    # generate iOS test report, and export
    slather coverage --llvm-cov --output-directory "llvm-cov" ${binary_basename:+--binary-basename "$binary_basename"} ${workspace:+--workspace "$ios_workspace"} ${scheme:+--scheme "$ios_scheme"} ${project:+"$ios_project"}
    mv llvm-cov/report.llcov $BITRISE_DEPLOY_DIR
    ;;
  android)
    # export Android test report
    mv $android_jacoco_xml $BITRISE_DEPLOY_DIR
    ;;
  *)
    echo "No report exported"
    ;;
esac

# trigger sonarqube
curl -X "POST" "https://$gitpub_sonar_bridge_host/rest/api/1.0/projects/$gitpub_sonar_bridge_owner/repos/$gitpub_sonar_bridge_repo/commits/$gitpub_sonar_bridge_commit_id/comments?path=$gitpub_sonar_bridge_file_path" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -u "$gitpub_username:$gitpub_password" \
     -d "{
  \"path\": \"$gitpub_sonar_bridge_file_path\",
  \"text\": \"{branchName:'$BITRISE_GIT_BRANCH',targetBranchName:'$BITRISEIO_GIT_BRANCH_DEST',pullRequestKey:'$BITRISE_PULL_REQUEST',repositoryURL:'$project_repository_url',commitHash:'$BITRISE_GIT_COMMIT',appSlug:'$BITRISE_APP_SLUG',buildSlug:'$BITRISE_BUILD_SLUG'}\"
}"
