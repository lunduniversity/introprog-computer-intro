#!/bin/bash

# This script creates a tag for the repository and pushes it to the remote
# repository. The remote repository is configured to trigger a GitHub Actions
# workflow when a new tag is pushed, which will create a release on GitHub
# using the tag.


# Check for the correct number of input parameters
if [ "$#" -ne 1 ]; then
    echo "Error: Incorrect number of arguments."
    echo "Usage: $0 <version-number>"
    echo "Example: $0 v1.0.1"
    exit 1
fi

# Define the tag and message
TAG="lab_$1"
MESSAGE="Release $TAG"

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
# git tag -a "$TAG" -m "$MESSAGE"
git tag -a "$TAG"

# Push the tag to the remote repository
git push origin "$TAG"

echo "Tag $TAG created and pushed successfully."
