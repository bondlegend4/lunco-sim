#!/bin/bash
set -e

echo "======================================"
echo "Building Modelica Models"
echo "======================================"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$SCRIPT_DIR/models"
BUILD_DIR="$SCRIPT_DIR/build"

# Create build directory
mkdir -p "$BUILD_DIR"

# Check if OpenModelica is installed
if ! command -v omc &> /dev/null; then
    echo "Error: OpenModelica compiler (omc) not found"
    echo "Please install OpenModelica from https://openmodelica.org/"
    exit 1
fi

echo "Using OpenModelica:"
omc --version

# Function to build a model
build_model() {
    local model_name=$1
    local model_file="$MODELS_DIR/$model_name.mo"
    
    if [ ! -f "$model_file" ]; then
        echo "Error: Model file not found: $model_file"
        return 1
    fi
    
    echo ""
    echo "Building: $model_name"
    echo "----------------------------------------"
    
    # Create build directory for this model
    local model_build_dir="$BUILD_DIR/$model_name"
    mkdir -p "$model_build_dir"
    cd "$model_build_dir"
    
    # Copy model file
    cp "$model_file" .
    
    # Compile with OpenModelica
    echo "Compiling $model_name.mo..."
    omc --simCodeTarget=C -s "$model_name.mo" 2>&1 | grep -v "^$" || true
    
    # Check if compilation was successful
    if [ -f "${model_name}.c" ]; then
        echo "✓ $model_name compiled successfully"
        echo "  Files generated: $(ls -1 | wc -l)"
        echo "  Location: $model_build_dir"
    else
        echo "✗ Failed to compile $model_name"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
}

# Build all models or specific model
if [ $# -eq 0 ]; then
    # Build all .mo files in models directory
    echo "Building all models in $MODELS_DIR"
    
    for model_file in "$MODELS_DIR"/*.mo; do
        if [ -f "$model_file" ]; then
            model_name=$(basename "$model_file" .mo)
            build_model "$model_name" || echo "Warning: Failed to build $model_name"
        fi
    done
else
    # Build specific model
    build_model "$1"
fi

echo ""
echo "======================================"
echo "✓ Build complete!"
echo "======================================"
echo ""
echo "Built models are in: $BUILD_DIR"
echo ""
echo "Next steps:"
echo "  1. Run: cd ../../../ && ./build.sh"
echo "  2. Open lunco-sim in Godot"
echo ""