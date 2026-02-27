#!/bin/bash

# CEREBRO - project init script
# run after setup_macos.sh has installed dependencies

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
}

print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BACKEND_DIR="$PROJECT_DIR/cerebro_backend"
FLUTTER_DIR="$PROJECT_DIR/cerebro_app"

print_header "CEREBRO PROJECT INITIALIZATION"

print_header "STEP 1/5: FLUTTER PROJECT SETUP"

if [ -d "$FLUTTER_DIR/android" ] || [ -d "$FLUTTER_DIR/macos" ]; then
    print_warning "Flutter project already initialized, skipping flutter create"
else
    print_step "Creating Flutter project..."

    # Save our custom files
    TEMP_DIR=$(mktemp -d)
    if [ -d "$FLUTTER_DIR/lib" ]; then
        cp -r "$FLUTTER_DIR/lib" "$TEMP_DIR/lib_backup"
    fi
    if [ -f "$FLUTTER_DIR/pubspec.yaml" ]; then
        cp "$FLUTTER_DIR/pubspec.yaml" "$TEMP_DIR/pubspec_backup.yaml"
    fi

    # Create Flutter project in a temp location, then merge
    flutter create --org com.cerebro --project-name cerebro_app "$FLUTTER_DIR.tmp"

    # Copy native platform files into our project
    cp -r "$FLUTTER_DIR.tmp/android" "$FLUTTER_DIR/" 2>/dev/null || true
    cp -r "$FLUTTER_DIR.tmp/ios" "$FLUTTER_DIR/" 2>/dev/null || true
    cp -r "$FLUTTER_DIR.tmp/macos" "$FLUTTER_DIR/" 2>/dev/null || true
    cp -r "$FLUTTER_DIR.tmp/linux" "$FLUTTER_DIR/" 2>/dev/null || true
    cp -r "$FLUTTER_DIR.tmp/web" "$FLUTTER_DIR/" 2>/dev/null || true
    cp -r "$FLUTTER_DIR.tmp/windows" "$FLUTTER_DIR/" 2>/dev/null || true
    cp -r "$FLUTTER_DIR.tmp/test" "$FLUTTER_DIR/" 2>/dev/null || true
    cp "$FLUTTER_DIR.tmp/analysis_options.yaml" "$FLUTTER_DIR/" 2>/dev/null || true

    # Restore our custom files (they take priority)
    if [ -d "$TEMP_DIR/lib_backup" ]; then
        cp -r "$TEMP_DIR/lib_backup/"* "$FLUTTER_DIR/lib/"
    fi
    if [ -f "$TEMP_DIR/pubspec_backup.yaml" ]; then
        cp "$TEMP_DIR/pubspec_backup.yaml" "$FLUTTER_DIR/pubspec.yaml"
    fi

    # Cleanup
    rm -rf "$FLUTTER_DIR.tmp" "$TEMP_DIR"

    print_success "Flutter project created with native platform files"
fi

# Create asset directories
print_step "Creating asset directories..."
mkdir -p "$FLUTTER_DIR/assets/images"
mkdir -p "$FLUTTER_DIR/assets/icons"
mkdir -p "$FLUTTER_DIR/assets/fonts"
print_success "Asset directories created"

# Install Flutter dependencies
print_step "Installing Flutter packages..."
cd "$FLUTTER_DIR"
flutter pub get
print_success "Flutter packages installed"

print_header "STEP 2/5: PYTHON BACKEND SETUP"

cd "$BACKEND_DIR"

# Detect Python command
PYTHON_CMD="python3"
if command -v python3.11 &> /dev/null; then
    PYTHON_CMD="python3.11"
fi

print_step "Creating Python virtual environment..."
$PYTHON_CMD -m venv venv
source venv/bin/activate
print_success "Virtual environment created"

print_step "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
print_success "Python dependencies installed"

print_header "STEP 3/5: DATABASE SETUP"

# Check if PostgreSQL is running
if pg_isready &> /dev/null; then
    print_success "PostgreSQL is running"

    # Create database if not exists
    print_step "Setting up CEREBRO database..."
    psql postgres -c "CREATE USER cerebro_admin WITH PASSWORD 'cerebro_dev_2026' SUPERUSER;" 2>/dev/null || print_warning "User already exists"
    psql postgres -c "CREATE DATABASE cerebro_db OWNER cerebro_admin;" 2>/dev/null || print_warning "Database already exists"

    # Run Alembic migration
    print_step "Running database migrations..."
    cd "$BACKEND_DIR"
    source venv/bin/activate
    alembic revision --autogenerate -m "Initial migration - all tables" 2>/dev/null || print_warning "Migration may already exist"
    alembic upgrade head 2>/dev/null || print_warning "Tables may already exist"

    print_success "Database setup complete"
else
    print_warning "PostgreSQL is not running. Start it with: brew services start postgresql@15"
    print_warning "Then re-run this script to set up the database."
fi

print_header "STEP 4/5: REDIS CHECK"

if redis-cli ping &> /dev/null; then
    print_success "Redis is running and responding"
else
    print_warning "Redis is not running. Start it with: brew services start redis"
fi

print_header "STEP 5/5: GIT SETUP"

cd "$PROJECT_DIR"

if [ -d ".git" ]; then
    print_warning "Git already initialized"
else
    print_step "Initializing Git repository..."
    git init

    # Create .gitignore
    cat > .gitignore << 'GITIGNORE'
# python
__pycache__/
*.py[cod]
*.egg-info/
venv/
.env
*.pkl

# flutter
cerebro_app/.dart_tool/
cerebro_app/.packages
cerebro_app/build/
cerebro_app/.flutter-plugins
cerebro_app/.flutter-plugins-dependencies
cerebro_app/pubspec.lock

# ide
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# database
*.db
*.sqlite3

# docker
docker-compose.override.yml
GITIGNORE

    git add -A
    git commit -m "Initial commit: CEREBRO project setup

- Flutter frontend with Riverpod + GoRouter
- FastAPI backend with SQLAlchemy + JWT auth
- Docker Compose for PostgreSQL + Redis
- Auth flow (email/password + Google OAuth)"

    print_success "Git repository initialized with initial commit"
fi

print_header "PROJECT INITIALIZATION COMPLETE!"

echo ""
echo -e "${GREEN}Your CEREBRO project is ready!${NC}"
echo ""
echo "  Project Structure:"
echo "  ─────────────────────────────────────────────"
echo "  cerebro_project/"
echo "  ├── cerebro_app/        Flutter frontend"
echo "  ├── cerebro_backend/    FastAPI backend"
echo "  ├── docker-compose.yml  PostgreSQL + Redis"
echo "  └── .env                Environment config"
echo ""
echo "  Quick Start Commands:"
echo "  ─────────────────────────────────────────────"
echo ""
echo -e "  ${CYAN}Start Backend:${NC}"
echo "    cd cerebro_backend"
echo "    source venv/bin/activate"
echo "    uvicorn app.main:app --reload --port 8000"
echo ""
echo -e "  ${CYAN}Start Frontend (new terminal):${NC}"
echo "    cd cerebro_app"
echo "    flutter run -d macos     # Desktop"
echo "    flutter run -d chrome    # Web"
echo ""
echo -e "  ${CYAN}API Docs:${NC}"
echo "    http://localhost:8000/docs     (Swagger UI)"
echo "    http://localhost:8000/redoc    (ReDoc)"
echo ""
echo -e "  ${CYAN}Database:${NC}"
echo "    psql -U cerebro_admin -d cerebro_db"
echo ""
echo -e "${GREEN}Happy coding! 🧠${NC}"
echo ""
