#!/bin/bash

# Clone the theme from the submodules
git submodule init
git submodule update

# Install required node_modules
cd themes/blowfish
npm install
# Compile the css
cd /src
npm run build

# Build the website files
hugo --minify
