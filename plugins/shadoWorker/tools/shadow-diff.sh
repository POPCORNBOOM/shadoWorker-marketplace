#!/bin/bash
# shadow-diff.sh - Compare shadow and working directory structures

set -euo pipefail

# Default configuration
MAX_DISPLAY=16
NO_COLLAPSE=false
TARGET_DIR=""

# Hardcoded ignore list
HARDCODED_IGNORES=(
    ".shadowignore"
    ".shadow"
    ".git"
)

show_help() {
    cat << EOF
Usage: shadow-diff.sh [OPTIONS]

Compare shadow and working directory structures.

OPTIONS:
  --max-display <N>     Max files to display per directory (default: 16)
  --dir <PATH>          Directory to compare (auto-detect shadow/working)
  --no-collapse         Disable collapsing, show all differences
  --help                Show this help message

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --max-display)
                MAX_DISPLAY="$2"
                shift 2
                ;;
            --dir)
                TARGET_DIR="$2"
                shift 2
                ;;
            --no-collapse)
                NO_COLLAPSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Detect shadow and working directory paths
detect_paths() {
    local input_path="$1"
    local shadow_dir=""
    local working_dir=""

    if [[ "$input_path" == *".shadow"* ]]; then
        # Input is a shadow directory
        shadow_dir="$input_path"
        working_dir="${input_path//.shadow\//}"
    else
        # Input is a working directory
        working_dir="$input_path"

        # Find project root by looking for .shadow directory
        local current_dir="$working_dir"
        local project_root=""

        while [[ "$current_dir" != "/" && "$current_dir" != "" ]]; do
            if [[ -d "$current_dir/.shadow" ]]; then
                project_root="$current_dir"
                break
            fi
            current_dir=$(dirname "$current_dir")
        done

        if [[ -z "$project_root" ]]; then
            echo "Error: Could not find .shadow directory in parent directories"
            exit 1
        fi

        # Calculate relative path from project root
        local rel_path="${working_dir#$project_root/}"
        shadow_dir="$project_root/.shadow/$rel_path"
    fi

    echo "$shadow_dir|$working_dir"
}

# Check if a path should be ignored
should_ignore() {
    local path="$1"
    local ignore_patterns=("${@:2}")

    local basename=$(basename "$path")

    # Check hardcoded ignores
    for ignore in "${HARDCODED_IGNORES[@]}"; do
        if [[ "$basename" == "$ignore" ]]; then
            return 0
        fi
    done

    # Check .shadowignore patterns
    for pattern in "${ignore_patterns[@]}"; do
        # Simple pattern matching (supports * wildcards)
        if [[ "$basename" == $pattern ]]; then
            return 0
        fi

        # Check if full path matches
        if [[ "$path" == *"$pattern"* ]]; then
            return 0
        fi
    done

    return 1
}

# Read .shadowignore file
read_shadowignore() {
    local working_dir="$1"
    local ignore_file="$working_dir/.shadowignore"
    local patterns=()

    if [[ -f "$ignore_file" ]]; then
        while IFS= read -r line; do
            # Skip empty lines and comments
            if [[ -n "$line" && ! "$line" =~ ^# ]]; then
                patterns+=("$line")
            fi
        done < "$ignore_file"
    fi

    echo "${patterns[@]}"
}

# Scan directory and collect files
scan_directory() {
    local dir="$1"
    shift
    local ignore_patterns=("$@")
    local files=()

    if [[ ! -d "$dir" ]]; then
        echo ""
        return
    fi

    while IFS= read -r -d '' file; do
        local rel_path="${file#$dir/}"

        if ! should_ignore "$rel_path" "${ignore_patterns[@]}"; then
            files+=("$rel_path")
        fi
    done < <(find "$dir" -type f -print0 2>/dev/null || true)

    printf '%s\n' "${files[@]}" | sort
}

# Format output with collapsing
format_output() {
    local title="$1"
    local -n missing_files=$2
    local max_display=$3
    local no_collapse=$4

    if [[ ${#missing_files[@]} -eq 0 ]]; then
        return
    fi

    echo ""
    echo "=== $title ==="

    declare -A dir_files
    local total_displayed=0
    local total_collapsed=0

    # Group files by directory
    for file in "${missing_files[@]}"; do
        local dir=$(dirname "$file")
        if [[ -z "${dir_files[$dir]}" ]]; then
            dir_files[$dir]="$file"
        else
            dir_files[$dir]="${dir_files[$dir]}|$file"
        fi
    done

    # Display files with collapsing
    for dir in $(printf '%s\n' "${!dir_files[@]}" | sort); do
        local file_list="${dir_files[$dir]}"
        IFS='|' read -ra files <<< "$file_list"
        local count=${#files[@]}

        if [[ "$no_collapse" == "true" || $count -le $max_display ]]; then
            # Display all files
            for file in "${files[@]}"; do
                echo "$file [MISSING]"
                ((total_displayed++))
            done
        else
            # Collapse directory
            echo "$dir/ [$count files omitted, exceeds limit of $max_display]"
            ((total_collapsed+=count))
        fi
    done
}

# Main function
main() {
    parse_args "$@"

    # Use current directory if not specified
    if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$(pwd)"
    fi

    # Convert to absolute path
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

    # Detect paths
    local paths=$(detect_paths "$TARGET_DIR")
    IFS='|' read -r shadow_dir working_dir <<< "$paths"

    # Read ignore patterns
    local ignore_patterns=($(read_shadowignore "$working_dir"))

    # Scan directories
    echo "Scanning directories..."
    local shadow_files=($(scan_directory "$shadow_dir" "${ignore_patterns[@]}"))
    local working_files=($(scan_directory "$working_dir" "${ignore_patterns[@]}"))

    # Convert shadow files to expected working files
    declare -A shadow_map
    declare -A working_map

    for file in "${shadow_files[@]}"; do
        # Remove .shadow.md extension
        local working_file="${file%.shadow.md}"
        shadow_map["$working_file"]=1
    done

    for file in "${working_files[@]}"; do
        working_map["$file"]=1
    done

    # Find missing files
    local shadow_missing=()
    local working_missing=()

    # Files in shadow but not in working
    for file in "${!shadow_map[@]}"; do
        if [[ -z "${working_map[$file]}" ]]; then
            shadow_missing+=("$file")
        fi
    done

    # Files in working but not in shadow
    for file in "${!working_map[@]}"; do
        local shadow_file="$file.shadow.md"
        local found=false
        for sf in "${shadow_files[@]}"; do
            if [[ "$sf" == "$shadow_file" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            working_missing+=("$file")
        fi
    done

    # Format and display output
    format_output "Shadow → Working" shadow_missing "$MAX_DISPLAY" "$NO_COLLAPSE"
    format_output "Working → Shadow" working_missing "$MAX_DISPLAY" "$NO_COLLAPSE"

    # Summary
    local shadow_count=${#shadow_missing[@]}
    local working_count=${#working_missing[@]}
    local total_collapsed=0

    # Calculate collapsed count
    if [[ "$NO_COLLAPSE" == "false" ]]; then
        declare -A dir_files
        for file in "${working_missing[@]}"; do
            local dir=$(dirname "$file")
            if [[ -z "${dir_files[$dir]}" ]]; then
                dir_files[$dir]=1
            else
                ((dir_files[$dir]++))
            fi
        done

        for dir in "${!dir_files[@]}"; do
            local count=${dir_files[$dir]}
            if [[ $count -gt $MAX_DISPLAY ]]; then
                ((total_collapsed+=count))
            fi
        done
    fi

    echo ""
    if [[ $total_collapsed -gt 0 ]]; then
        echo "Total: $shadow_count shadow missing, $working_count working missing ($total_collapsed collapsed)"
    else
        echo "Total: $shadow_count shadow missing, $working_count working missing"
    fi
}

# Run main function
main "$@"
