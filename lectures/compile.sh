#!/bin/bash

# Check for no input arguments and print usage if none are found
if [ $# -eq 0 ]; then
    echo "Usage: $0 <document1> [<document2> ...]"
    echo "Documents: intro, unix, git, latex, machine-code"
    exit 1
fi

# Array of subdirectory names you want to compile (passed as command-line arguments)
subdirectories=("$@")

# Loop through each subdirectory
for dir in "${subdirectories[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Directory $dir does not exist."
        continue
    fi

    # Navigate into the directory
    cd "$dir"
    
    # Compile the presentation version of the LaTeX file
    latexmk -xelatex slides.tex
    
    # # Check if presentation compilation was successful
    if [ -f slides.pdf ]; then
        # Define new PDF name for the presentation version
        presentation_pdf_name="../lecture-$dir-presentation.pdf"
        
        # Copy and rename the compiled PDF to the main directory
        cp slides.pdf "$presentation_pdf_name"
    else
        echo "Presentation compilation failed in $dir"
    fi

    # Compile the handout version of the LaTeX file with the \ishandout definition
    latexmk -xelatex slides_handout.tex

    # Check if handout compilation was successful
    if [ -f slides_handout.pdf ]; then
        # Define new PDF name for the handout version
        handout_pdf_name="../lecture-$dir-handout.pdf"
        
        # Copy and rename the compiled PDF to the main directory
        cp slides_handout.pdf "$handout_pdf_name"
    else
        echo "Handout compilation failed in $dir"
    fi
    
    # Go back to the main directory
    cd ..
done

echo "All operations completed."
