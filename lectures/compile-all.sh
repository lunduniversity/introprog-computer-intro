#!/bin/bash

# Array of subdirectory names
subdirectories=("intro" "unix" "git" "latex" "machine-code")

# Counter for lecture number
lecture_number=0

# Arrays to hold paths of PDFs for final merge
presentation_pdfs=()
handout_pdfs=()

# Loop through each subdirectory
for dir in "${subdirectories[@]}"; do
    # Navigate into the directory
    cd "$dir"
    
    # Compile the presentation version of the LaTeX file
    latexmk -xelatex slides.tex
    
    # # Check if presentation compilation was successful
    if [ -f slides.pdf ]; then
        # Define new PDF name for the presentation version
        presentation_pdf_name="../lecture${lecture_number}-$dir-presentation.pdf"
        
        # Copy and rename the compiled PDF to the main directory
        cp slides.pdf "$presentation_pdf_name"
        
        # Add the presentation PDF name to the array for merging
        presentation_pdfs+=("$presentation_pdf_name")
    else
        echo "Presentation compilation failed in $dir"
    fi

    # Compile the handout version of the LaTeX file with the \ishandout definition
    latexmk -xelatex slides_handout.tex

    # Check if handout compilation was successful
    if [ -f slides_handout.pdf ]; then
        # Define new PDF name for the handout version
        handout_pdf_name="../lecture${lecture_number}-$dir-handout.pdf"
        
        # Copy and rename the compiled PDF to the main directory
        cp slides_handout.pdf "$handout_pdf_name"
        
        # Add the handout PDF name to the array for merging
        handout_pdfs+=("$handout_pdf_name")
    else
        echo "Handout compilation failed in $dir"
    fi
    
    # Increment the lecture number
    ((lecture_number++))
    
    # Go back to the main directory
    cd ..
done

# Merge all presentation PDFs into one file
# pdfunite "${presentation_pdfs[@]}" "lecture1-$((${lecture_number}-1))-all-presentations.pdf"

# Merge all handout PDFs into one file
pdfunite "${handout_pdfs[@]}" "lecture1-$((${lecture_number}-1))-all-handouts.pdf"


echo "All operations completed."
