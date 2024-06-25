#!/bin/bash

# Array of subdirectory names
subdirectories=("intro" "unix" "git" "latex" "machine-code")

# Counter for lecture number
lecture_number=0

# Array to hold paths of PDFs for final merge
pdf_files=()

# Loop through each subdirectory
for dir in "${subdirectories[@]}"; do
    # Navigate into the directory
    cd "$dir"
    
    # Compile the LaTeX file
    pdflatex slides.tex
    
    # Check if compilation was successful
    if [ -f slides.pdf ]; then
        # Define new PDF name based on lecture number and directory name
        new_pdf_name="../lecture${lecture_number}-$dir.pdf"
        
        # Copy and rename the compiled PDF to the main directory
        cp slides.pdf "$new_pdf_name"
        
        # Add the new PDF name to the array for merging
        pdf_files+=("$new_pdf_name")
        
        # Increment the lecture number
        ((lecture_number++))
    else
        echo "Compilation failed in $dir"
    fi
    
    # Go back to the main directory
    cd ..
done

# Merge all PDF files into one
pdfunite "${pdf_files[@]}" "lecture1-$((${lecture_number}-1))-all.pdf"

echo "All operations completed."
