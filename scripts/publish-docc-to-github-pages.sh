#!/bin/bash

# Script to generate DocC documentation and publish it to GitHub Pages
# This script generates documentation using xcodebuild docbuild
# and publishes it to a GitHub Pages repository (rickhohler.github.io)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_NAME="DesignAlgorithmsKit"

# Get GitHub username
# In GitHub Actions, use GITHUB_REPOSITORY_OWNER if available
if [ -n "$GITHUB_ACTIONS" ] && [ -n "$GITHUB_REPOSITORY_OWNER" ]; then
    GITHUB_USER="$GITHUB_REPOSITORY_OWNER"
elif [ -n "$GITHUB_ACTIONS" ] && [ -n "$GITHUB_REPOSITORY" ]; then
    # Extract username from GITHUB_REPOSITORY (format: owner/repo)
    GITHUB_USER=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f1)
elif [ -n "$GH_TOKEN" ] || [ -n "$GITHUB_TOKEN" ]; then
    # Try to get username from GitHub API using token
    GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null || echo "")
    if [ -z "$GITHUB_USER" ]; then
        echo -e "${YELLOW}Warning: Could not get username from API, trying GITHUB_REPOSITORY${NC}"
        if [ -n "$GITHUB_REPOSITORY" ]; then
            GITHUB_USER=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f1)
        fi
    fi
else
    GITHUB_USER=$(gh api user --jq '.login')
fi
if [ -z "$GITHUB_USER" ]; then
    echo -e "${RED}Error: Could not get GitHub username${NC}"
    exit 1
fi

# GitHub Pages repository name (typically username.github.io)
GITHUB_PAGES_REPO="${GITHUB_USER}.github.io"
GITHUB_PAGES_URL="https://github.com/${GITHUB_USER}/${GITHUB_PAGES_REPO}.git"

# Local clone directory - try to use existing clone, otherwise use temp location
# In GitHub Actions, use a temp directory
if [ -n "$GITHUB_ACTIONS" ]; then
    CLONE_DIR="${REPO_ROOT}/.github-pages-clone"
elif [ -d "/Users/${GITHUB_USER}/CODE/GITHUB/${GITHUB_PAGES_REPO}" ]; then
    CLONE_DIR="/Users/${GITHUB_USER}/CODE/GITHUB/${GITHUB_PAGES_REPO}"
else
    CLONE_DIR="${REPO_ROOT}/.github-pages-clone"
fi

echo -e "${GREEN}DocC Documentation Publisher${NC}"
echo "User: $GITHUB_USER"
echo "Repository: $GITHUB_PAGES_REPO"
echo "Package: $PACKAGE_NAME"
echo ""

# Change to repository root
cd "$REPO_ROOT"

# Generate DocC documentation using xcodebuild
echo -e "${GREEN}Generating DocC documentation...${NC}"

# Create a temporary directory for docbuild output
DOCBUILD_DIR="${REPO_ROOT}/.docbuild"
rm -rf "$DOCBUILD_DIR"
mkdir -p "$DOCBUILD_DIR"

# Generate documentation using Swift DocC Plugin
echo "Generating documentation with Swift DocC Plugin..."
cd "$REPO_ROOT"

# Resolve package dependencies first
swift package resolve

# Convert package name to lowercase (bash 3.2 compatible)
PACKAGE_NAME_LOWER=$(echo "$PACKAGE_NAME" | tr '[:upper:]' '[:lower:]')

# Generate documentation using swift package generate-documentation
# This requires the swift-docc-plugin to be added to Package.swift
if swift package --allow-writing-to-directory "$DOCBUILD_DIR" \
    generate-documentation \
    --target "$PACKAGE_NAME" \
    --output-path "$DOCBUILD_DIR" \
    --transform-for-static-hosting \
    --hosting-base-path "/${PACKAGE_NAME_LOWER}" 2>&1; then
    echo -e "${GREEN}DocC documentation generated successfully${NC}"
    
    # The documentation is already transformed for static hosting in DOCBUILD_DIR
    STATIC_DOCS_DIR="$DOCBUILD_DIR"
    
    if [ -d "$STATIC_DOCS_DIR" ] && [ -n "$(ls -A "$STATIC_DOCS_DIR" 2>/dev/null)" ]; then
        echo "Found generated documentation in: $STATIC_DOCS_DIR"
    else
        echo -e "${YELLOW}Documentation directory is empty, creating static fallback site${NC}"
        STATIC_DOCS_DIR=""
    fi
else
    echo -e "${YELLOW}swift package generate-documentation failed, creating static fallback site${NC}"
    STATIC_DOCS_DIR=""
fi

# Clone or update the GitHub Pages repository
if [ -d "$CLONE_DIR" ] && [ -d "$CLONE_DIR/.git" ]; then
    echo "Updating existing clone..."
    cd "$CLONE_DIR"
    # Try master first (common for older repos), then main
    git pull origin master 2>/dev/null || git pull origin main 2>/dev/null || true
else
    echo "Cloning GitHub Pages repository..."
    # In GitHub Actions, use token for authentication
    if [ -n "$GITHUB_ACTIONS" ] && [ -n "$GITHUB_TOKEN" ]; then
        # Try using gh CLI first (handles authentication better)
        if command -v gh >/dev/null 2>&1; then
            gh repo clone "${GITHUB_USER}/${GITHUB_PAGES_REPO}" "$CLONE_DIR" 2>/dev/null || {
                echo -e "${YELLOW}gh clone failed, trying git with token...${NC}"
                # Fallback to git with token in URL
                git config --global credential.helper store
                echo "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
                git clone "https://github.com/${GITHUB_USER}/${GITHUB_PAGES_REPO}.git" "$CLONE_DIR" || {
                    echo -e "${RED}Error: Could not clone repository.${NC}"
                    echo "Repository: https://github.com/${GITHUB_USER}/${GITHUB_PAGES_REPO}.git"
                    echo ""
                    echo -e "${YELLOW}Note: GITHUB_TOKEN in GitHub Actions only has access to the current repository.${NC}"
                    echo "To access other repositories, create a Personal Access Token (PAT) with 'repo' scope:"
                    echo "1. Go to https://github.com/settings/tokens"
                    echo "2. Generate a new token with 'repo' scope"
                    echo "3. Add it as a secret named 'GH_PAT' in your repository settings"
                    echo "4. The workflow will automatically use GH_PAT if available"
                    exit 1
                }
            }
        else
            # gh CLI not available, use git with token
            git config --global credential.helper store
            echo "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
            git clone "https://github.com/${GITHUB_USER}/${GITHUB_PAGES_REPO}.git" "$CLONE_DIR" || {
                echo -e "${RED}Error: Could not clone repository.${NC}"
                echo "Repository: https://github.com/${GITHUB_USER}/${GITHUB_PAGES_REPO}.git"
                echo ""
                echo -e "${YELLOW}Note: GITHUB_TOKEN in GitHub Actions only has access to the current repository.${NC}"
                echo "To access other repositories, create a Personal Access Token (PAT) with 'repo' scope:"
                echo "1. Go to https://github.com/settings/tokens"
                echo "2. Generate a new token with 'repo' scope"
                echo "3. Add it as a secret named 'GH_PAT' in your repository settings"
                exit 1
            }
        fi
    else
        git clone "$GITHUB_PAGES_URL" "$CLONE_DIR" || {
            echo -e "${RED}Error: Could not clone repository.${NC}"
            echo "Repository: $GITHUB_PAGES_URL"
            echo "Please ensure the repository exists and you have access."
            exit 1
        }
    fi
    cd "$CLONE_DIR"
fi

# Determine the documentation directory
# For Swift packages, we'll publish to a subdirectory like /designalgorithmskit/
DOCS_DIR="$PACKAGE_NAME_LOWER"  # Use lowercase version
mkdir -p "$DOCS_DIR"

echo "Using documentation directory: $DOCS_DIR"
echo ""

# Copy documentation to GitHub Pages repository
if [ -n "$STATIC_DOCS_DIR" ] && [ -d "$STATIC_DOCS_DIR" ]; then
    echo -e "${GREEN}Copying DocC documentation to GitHub Pages...${NC}"
    echo "Source: $STATIC_DOCS_DIR"
    echo "Destination: $CLONE_DIR/$DOCS_DIR"
    
    # Remove existing documentation
    rm -rf "$CLONE_DIR/$DOCS_DIR"/*
    
    # Copy the entire documentation contents
    cp -R "$STATIC_DOCS_DIR"/* "$CLONE_DIR/$DOCS_DIR/" || {
        echo -e "${RED}Error: Failed to copy documentation${NC}"
        exit 1
    }
    
    # Create a simplified index.html that redirects to the documentation
    echo -e "${GREEN}Creating simplified index.html...${NC}"
    cat > "$CLONE_DIR/$DOCS_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="refresh" content="0; url=/${DOCS_DIR}/documentation/${PACKAGE_NAME_LOWER}/">
    <title>${PACKAGE_NAME} Documentation</title>
    <script>
        window.location.href = "/${DOCS_DIR}/documentation/${PACKAGE_NAME_LOWER}/";
    </script>
</head>
<body>
    <p>Redirecting to <a href="/${DOCS_DIR}/documentation/${PACKAGE_NAME,,}/">${PACKAGE_NAME} Documentation</a>...</p>
</body>
</html>
EOF
    
    echo -e "${GREEN}Documentation copied successfully${NC}"
else
    echo -e "${YELLOW}DocC documentation not found, creating static fallback site${NC}"
    # Create a simple static HTML site as fallback
    cat > "$CLONE_DIR/$DOCS_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DesignAlgorithmsKit Documentation</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
            max-width: 900px;
            margin: 0 auto;
            padding: 40px 20px;
            line-height: 1.6;
            color: #24292e;
        }
        h1 { color: #0366d6; border-bottom: 2px solid #eaecef; padding-bottom: 10px; }
        h2 { color: #24292e; margin-top: 30px; }
        .links { margin: 30px 0; }
        .links a {
            display: inline-block;
            margin: 10px 10px 10px 0;
            padding: 12px 24px;
            background: #0366d6;
            color: white;
            text-decoration: none;
            border-radius: 6px;
            font-weight: 500;
        }
        .links a:hover { background: #0256c2; }
        ul { line-height: 1.8; }
        code { background: #f6f8fa; padding: 2px 6px; border-radius: 3px; font-family: 'SF Mono', Monaco, monospace; }
        .section { margin: 30px 0; }
    </style>
</head>
<body>
    <h1>DesignAlgorithmsKit</h1>
    <p>A Swift package providing common design patterns and algorithms with protocols and base types for extensibility.</p>
    
    <div class="links">
        <a href="https://github.com/rickhohler/DesignAlgorithmsKit#readme">View README</a>
        <a href="https://github.com/rickhohler/DesignAlgorithmsKit">GitHub Repository</a>
    </div>
    
    <div class="section">
        <h2>Design Patterns</h2>
        <ul>
            <li><strong>Registry Pattern</strong> - <code>TypeRegistry</code> for centralized type registration</li>
            <li><strong>Factory Pattern</strong> - <code>ObjectFactory</code> for object creation</li>
            <li><strong>Builder Pattern</strong> - <code>BaseBuilder</code> for fluent API construction</li>
            <li><strong>Singleton Pattern</strong> - <code>ThreadSafeSingleton</code> and <code>ActorSingleton</code></li>
            <li><strong>Strategy Pattern</strong> - <code>Strategy</code> protocol and <code>StrategyContext</code></li>
            <li><strong>Observer Pattern</strong> - <code>Observer</code> and <code>Observable</code> protocols</li>
            <li><strong>Adapter Pattern</strong> - <code>Adapter</code> protocol</li>
            <li><strong>Facade Pattern</strong> - <code>Facade</code> protocol</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Algorithms</h2>
        <ul>
            <li><strong>Merkle Tree</strong> - Data structure for efficient data verification</li>
            <li><strong>Bloom Filter</strong> - Probabilistic data structure for membership testing</li>
            <li><strong>Counting Bloom Filter</strong> - Bloom filter variant supporting element removal</li>
            <li><strong>Hash Algorithms</strong> - SHA256 and other hash implementations</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Usage</h2>
        <p>Add DesignAlgorithmsKit to your <code>Package.swift</code>:</p>
        <pre style="background: #f6f8fa; padding: 15px; border-radius: 6px; overflow-x: auto;"><code>.package(url: "https://github.com/rickhohler/DesignAlgorithmsKit.git", from: "1.0.0")</code></pre>
        <p><em>For detailed API documentation, see the README and source code comments.</em></p>
    </div>
</body>
</html>
EOF
fi

# Commit and push changes
cd "$CLONE_DIR"
git add "$DOCS_DIR" || true
git add -A || true

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
else
    echo -e "${GREEN}Committing changes...${NC}"
    git commit -m "Update $PACKAGE_NAME documentation" || {
        echo -e "${YELLOW}No changes to commit${NC}"
    }
    
    echo -e "${GREEN}Pushing to GitHub Pages...${NC}"
    # Try master first (common for older repos), then main
    git push origin master 2>/dev/null || git push origin main 2>/dev/null || {
        echo -e "${RED}Error: Failed to push to GitHub Pages repository${NC}"
        exit 1
    }
    
    echo -e "${GREEN}Documentation published successfully!${NC}"
    echo "Documentation will be available at: https://${GITHUB_USER}.github.io/${DOCS_DIR}/"
fi

# Cleanup
cd "$REPO_ROOT"
rm -rf "$DOCBUILD_DIR" "$STATIC_DOCS_DIR" 2>/dev/null || true
