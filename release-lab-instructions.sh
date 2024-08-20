#!/bin/bash

# This script creates a tag for the repository and pushes it to the remote
# repository. The remote repository is configured to trigger a GitHub Actions
# workflow when a new tag is pushed, which will create a release on GitHub
# using the tag.

# Usage: ./release-lab-instructions <version-number> ["Optional tag commit message"]

# Check for the correct number of input parameters
if [ "$#" -lt 1 ]; then
    echo "Error: Incorrect number of arguments."
    echo "Usage: $0 <version-number> [\"tag commit message\"]"
    echo "Example: $0 v1.0.1 \"Initial release\""
    echo "If no commit message is specified, the default editor will be opened."
    exit 1
fi


# Define the tag and message
TAG="lab_$1"
MESSAGE="Lab instructions $1"

# Check if the tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Error: Tag $TAG already exists."

    # Ask user if they want to replace the existing tag
    read -p "Do you want to replace the existing tag? (y/n) " answer
    case $answer in
        [Yy]* )
            # Delete the tag locally
            git tag -d "$TAG"
            # Delete the tag from the remote
            git push origin --delete "$TAG"
            ;;
        * )
            echo "Operation aborted."
            exit 1
            ;;
    esac
fi

# Create the annotated tag
if [ -z "$2" ]; then
    # If no message is provided, open the editor to allow the user to enter a message
    git tag -a "$TAG"
else
    # If a message is provided, use it directly
    git tag -a "$TAG" -m "$2"
fi

# Push the tag to the remote repository
git push origin "$TAG"

echo "Tag $TAG created and pushed successfully."
