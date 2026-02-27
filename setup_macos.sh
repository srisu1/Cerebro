#!/bin/bash

# CEREBRO - macOS dev setup
# installs homebrew, python, flutter, postgres, redis etc

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# step 1: homebrew
print_header "STEP 1/7: HOMEBREW (Package Manager)"

if command -v brew &> /dev/null; then
    print_success "Homebrew already installed: $(brew --version | head -1)"
    brew update
else
    print_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    print_success "Homebrew installed"
fi

# step 2: git
print_header "STEP 2/7: GIT (Version Control)"

if command -v git &> /dev/null; then
    print_success "Git already installed: $(git --version)"
else
    print_step "Installing Git..."
    brew install git
    print_success "Git installed"
fi

# step 3: flutter
print_header "STEP 3/7: FLUTTER & DART (Frontend Framework)"

if command -v flutter &> /dev/null; then
    print_success "Flutter already installed"
    flutter --version
else
    print_step "Installing Flutter SDK..."
    brew install --cask flutter

    # Add to PATH if needed
    export PATH="$PATH:$(brew --prefix)/Caskroom/flutter/*/flutter/bin"

    print_success "Flutter SDK installed"
fi

# Accept Android licenses (needed even for desktop/web)
print_step "Running Flutter doctor..."
flutter doctor --android-licenses 2>/dev/null || true
flutter doctor

# Enable desktop and web support
print_step "Enabling Flutter platforms..."
flutter config --enable-macos-desktop
flutter config --enable-web
print_success "Flutter platforms enabled (macOS desktop + web)"

# step 4: python
print_header "STEP 4/7: PYTHON 3.11+ (Backend Language)"

# Check for Python 3.11+
PYTHON_CMD=""
if command -v python3.11 &> /dev/null; then
    PYTHON_CMD="python3.11"
    print_success "Python 3.11 already installed"
elif command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    PY_MAJOR=$(echo $PY_VERSION | cut -d. -f1)
    PY_MINOR=$(echo $PY_VERSION | cut -d. -f2)
    if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 11 ]; then
        PYTHON_CMD="python3"
        print_success "Python $PY_VERSION already installed"
    else
        print_warning "Python $PY_VERSION found, but we need 3.11+. Installing..."
        brew install python@3.11
        PYTHON_CMD="python3.11"
        print_success "Python 3.11 installed"
    fi
else
    print_step "Installing Python 3.11..."
    brew install python@3.11
    PYTHON_CMD="python3.11"
    print_success "Python 3.11 installed"
fi

echo "Using: $($PYTHON_CMD --version)"

# Install pip if needed
$PYTHON_CMD -m ensurepip --upgrade 2>/dev/null || true

# step 5: postgresql
print_header "STEP 5/7: POSTGRESQL 15+ (Database)"

if command -v psql &> /dev/null; then
    print_success "PostgreSQL already installed: $(psql --version)"
else
    print_step "Installing PostgreSQL 15..."
    brew install postgresql@15

    # Add to PATH
    echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zprofile
    export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

    print_success "PostgreSQL 15 installed"
fi

# Start PostgreSQL service
print_step "Starting PostgreSQL service..."
brew services start postgresql@15 2>/dev/null || brew services start postgresql 2>/dev/null || true
sleep 2
print_success "PostgreSQL service started"

# Create CEREBRO database and user
print_step "Setting up CEREBRO database..."
psql postgres -c "CREATE USER cerebro_admin WITH PASSWORD 'cerebro_dev_2026' SUPERUSER;" 2>/dev/null || print_warning "User cerebro_admin may already exist"
psql postgres -c "CREATE DATABASE cerebro_db OWNER cerebro_admin;" 2>/dev/null || print_warning "Database cerebro_db may already exist"
psql postgres -c "CREATE DATABASE cerebro_test_db OWNER cerebro_admin;" 2>/dev/null || print_warning "Test database may already exist"
print_success "Database 'cerebro_db' ready (user: cerebro_admin)"

# step 6: redis
print_header "STEP 6/7: REDIS (Caching Layer)"

if command -v redis-server &> /dev/null; then
    print_success "Redis already installed: $(redis-server --version | head -1)"
else
    print_step "Installing Redis..."
    brew install redis
    print_success "Redis installed"
fi

# Start Redis service
print_step "Starting Redis service..."
brew services start redis
print_success "Redis service started on port 6379"

# step 7: docker (optional)
print_header "STEP 7/7: DOCKER (Optional)"

if command -v docker &> /dev/null; then
    print_success "Docker already installed: $(docker --version)"
else
    print_warning "Docker Desktop not found."
    print_warning "Docker is OPTIONAL for development (we're using local PostgreSQL + Redis)."
    print_warning "Install later if needed: brew install --cask docker"
fi

# done
print_header "SETUP COMPLETE!"

echo -e "${GREEN}All dependencies installed successfully!${NC}"
echo ""
echo "  Tool          Status"
echo "  ─────────────────────────────────"

# Check each tool
for tool in "brew:Homebrew" "git:Git" "flutter:Flutter" "dart:Dart" "python3:Python" "psql:PostgreSQL" "redis-server:Redis"; do
    cmd=$(echo $tool | cut -d: -f1)
    name=$(echo $tool | cut -d: -f2)
    if command -v $cmd &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $name"
    else
        echo -e "  ${RED}✗${NC} $name"
    fi
done

echo ""
echo -e "${CYAN}Next step: Run the project initialization script:${NC}"
echo -e "${YELLOW}  cd cerebro_project && chmod +x init_project.sh && ./init_project.sh${NC}"
echo ""
