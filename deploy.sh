#!/bin/bash

#############################################################################
# Membership Management System - Deployment Script
# Version: 2.0.0
# Description: Complete deployment script for Ubuntu/Debian servers
# Features: No Docker, SSL automation, health checks, rollback support
#############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="choo-system"
APP_USER="choo"
APP_DIR="/var/www/choo-system"
BACKUP_DIR="/var/backups/choo-system"
NODE_VERSION="18"
DOMAIN=""
EMAIL=""
PORT=5173

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to get user input
get_configuration() {
    print_info "=== Choo Membership Management System Deployment ==="
    echo ""
    
    # Get domain
    read -p "Enter your domain name (e.g., member.example.com): " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        print_error "Domain name is required"
        exit 1
    fi
    
    # Get email for SSL
    read -p "Enter your email for SSL certificates: " EMAIL
    if [[ -z "$EMAIL" ]]; then
        print_error "Email is required for SSL certificates"
        exit 1
    fi
    
    # Get port (optional)
    read -p "Enter application port (default: 5173): " input_port
    if [[ ! -z "$input_port" ]]; then
        PORT=$input_port
    fi
    
    echo ""
    print_info "Configuration:"
    echo "  Domain: $DOMAIN"
    echo "  Email: $EMAIL"
    echo "  Port: $PORT"
    echo "  App Directory: $APP_DIR"
    echo ""
    
    read -p "Continue with this configuration? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        print_warning "Deployment cancelled"
        exit 0
    fi
}

# Function to update system packages
update_system() {
    print_info "Updating system packages..."
    apt update
    apt upgrade -y
    print_success "System packages updated"
}

# Function to install Node.js
install_nodejs() {
    print_info "Installing Node.js ${NODE_VERSION}..."
    
    # Check if Node.js is already installed
    if command -v node &> /dev/null; then
        current_version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$current_version" -ge "$NODE_VERSION" ]]; then
            print_success "Node.js ${current_version} is already installed"
            return
        fi
    fi
    
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt install -y nodejs
    
    # Verify installation
    node_version=$(node -v)
    npm_version=$(npm -v)
    print_success "Node.js ${node_version} and npm ${npm_version} installed"
}

# Function to install PM2
install_pm2() {
    print_info "Installing PM2..."
    
    if command -v pm2 &> /dev/null; then
        print_success "PM2 is already installed"
        return
    fi
    
    npm install -g pm2
    print_success "PM2 installed"
}

# Function to install Nginx
install_nginx() {
    print_info "Installing Nginx..."
    
    if command -v nginx &> /dev/null; then
        print_success "Nginx is already installed"
        return
    fi
    
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    print_success "Nginx installed and started"
}

# Function to install Certbot
install_certbot() {
    print_info "Installing Certbot..."
    
    if command -v certbot &> /dev/null; then
        print_success "Certbot is already installed"
        return
    fi
    
    apt install -y certbot python3-certbot-nginx
    print_success "Certbot installed"
}

# Function to create application user
create_app_user() {
    print_info "Creating application user..."
    
    if id "$APP_USER" &>/dev/null; then
        print_success "User $APP_USER already exists"
        return
    fi
    
    useradd -r -s /bin/bash -d /home/$APP_USER -m $APP_USER
    print_success "User $APP_USER created"
}

# Function to create directories
create_directories() {
    print_info "Creating application directories..."
    
    mkdir -p $APP_DIR
    mkdir -p $BACKUP_DIR
    mkdir -p /var/log/$APP_NAME
    
    chown -R $APP_USER:$APP_USER $APP_DIR
    chown -R $APP_USER:$APP_USER $BACKUP_DIR
    chown -R $APP_USER:$APP_USER /var/log/$APP_NAME
    
    print_success "Directories created"
}

# Function to copy application files
copy_application() {
    print_info "Copying application files..."
    
    # Create backup if app exists
    if [ -d "$APP_DIR/src" ]; then
        backup_name="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        print_info "Creating backup: $backup_name"
        tar -czf "$BACKUP_DIR/$backup_name" \
            --exclude=node_modules \
            --exclude=dist \
            -C $(dirname $APP_DIR) $(basename $APP_DIR)
        print_success "Backup created"
    fi
    
    # Copy files
    cp -r ./* $APP_DIR/
    chown -R $APP_USER:$APP_USER $APP_DIR
    
    print_success "Application files copied"
}

# Function to install dependencies
install_dependencies() {
    print_info "Installing application dependencies..."
    
    cd $APP_DIR
    sudo -u $APP_USER npm ci --production
    
    print_success "Dependencies installed"
}

# Function to build application
build_application() {
    print_info "Building application..."
    
    cd $APP_DIR
    sudo -u $APP_USER npm run build
    
    print_success "Application built"
}

# Function to configure environment
configure_environment() {
    print_info "Configuring environment..."
    
    if [ ! -f "$APP_DIR/.env" ]; then
        if [ -f "$APP_DIR/.env.example" ]; then
            cp $APP_DIR/.env.example $APP_DIR/.env
            print_warning "Created .env from .env.example"
            print_warning "Please edit $APP_DIR/.env with your Supabase credentials"
            print_warning "Press Enter when ready to continue..."
            read
        else
            print_error ".env.example not found"
            exit 1
        fi
    fi
    
    chown $APP_USER:$APP_USER $APP_DIR/.env
    chmod 600 $APP_DIR/.env
    
    print_success "Environment configured"
}

# Function to create server.js
create_server() {
    print_info "Creating production server..."
    
    cat > $APP_DIR/server.js << 'EOF'
import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 5173;

// Serve static files from dist directory
app.use(express.static(join(__dirname, 'dist')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// SPA fallback - serve index.html for all other routes
app.get('*', (req, res) => {
  res.sendFile(join(__dirname, 'dist', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF
    
    chown $APP_USER:$APP_USER $APP_DIR/server.js
    print_success "Production server created"
}

# Function to create PM2 ecosystem file
create_pm2_config() {
    print_info "Creating PM2 configuration..."
    
    cat > $APP_DIR/ecosystem.config.cjs << EOF
module.exports = {
  apps: [{
    name: '$APP_NAME',
    script: './server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: $PORT
    },
    error_file: '/var/log/$APP_NAME/error.log',
    out_file: '/var/log/$APP_NAME/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    max_memory_restart: '500M'
  }]
};
EOF
    
    chown $APP_USER:$APP_USER $APP_DIR/ecosystem.config.cjs
    print_success "PM2 configuration created"
}

# Function to start application with PM2
start_application() {
    print_info "Starting application with PM2..."
    
    cd $APP_DIR
    
    # Stop existing process if running
    sudo -u $APP_USER pm2 delete $APP_NAME 2>/dev/null || true
    
    # Start application
    sudo -u $APP_USER pm2 start ecosystem.config.cjs
    sudo -u $APP_USER pm2 save
    
    # Setup PM2 startup script
    env PATH=$PATH:/usr/bin pm2 startup systemd -u $APP_USER --hp /home/$APP_USER
    
    print_success "Application started"
}

# Function to configure Nginx
configure_nginx() {
    print_info "Configuring Nginx..."
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/$APP_NAME << EOF
# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN *.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN *.$DOMAIN;
    
    # SSL Configuration (will be updated by Certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json application/javascript;
    
    # Proxy to Node.js application
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:$PORT/health;
        access_log off;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    nginx -t
    
    # Reload Nginx
    systemctl reload nginx
    
    print_success "Nginx configured"
}

# Function to obtain SSL certificate
obtain_ssl() {
    print_info "Obtaining SSL certificate..."
    
    # Create directory for ACME challenge
    mkdir -p /var/www/certbot
    
    # Obtain certificate
    certbot --nginx -d $DOMAIN -d "*.$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --email $EMAIL \
        --redirect
    
    # Setup auto-renewal
    systemctl enable certbot.timer
    systemctl start certbot.timer
    
    print_success "SSL certificate obtained and auto-renewal configured"
}

# Function to setup firewall
setup_firewall() {
    print_info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
        print_success "Firewall configured"
    else
        print_warning "UFW not installed, skipping firewall configuration"
    fi
}

# Function to create update script
create_update_script() {
    print_info "Creating update script..."
    
    cat > /usr/local/bin/update-choo-system << 'EOFUPDATE'
#!/bin/bash

APP_DIR="/var/www/choo-system"
APP_USER="choo"
BACKUP_DIR="/var/backups/choo-system"

echo "Updating Choo Membership Management System..."

# Create backup
backup_name="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
echo "Creating backup: $backup_name"
tar -czf "$BACKUP_DIR/$backup_name" \
    --exclude=node_modules \
    --exclude=dist \
    -C $(dirname $APP_DIR) $(basename $APP_DIR)

# Pull latest changes (if using git)
cd $APP_DIR
if [ -d ".git" ]; then
    sudo -u $APP_USER git pull
fi

# Install dependencies
sudo -u $APP_USER npm ci --production

# Build application
sudo -u $APP_USER npm run build

# Restart application
sudo -u $APP_USER pm2 restart choo-system

echo "Update complete!"
EOFUPDATE
    
    chmod +x /usr/local/bin/update-choo-system
    print_success "Update script created at /usr/local/bin/update-choo-system"
}

# Function to display completion message
display_completion() {
    echo ""
    print_success "=== Deployment Complete ==="
    echo ""
    echo "Your Choo membership management system is now deployed!"
    echo ""
    echo "Important Information:"
    echo "  - Application URL: https://$DOMAIN"
    echo "  - Application Directory: $APP_DIR"
    echo "  - Logs Directory: /var/log/$APP_NAME"
    echo "  - Backups Directory: $BACKUP_DIR"
    echo ""
    echo "Next Steps:"
    echo "  1. Edit $APP_DIR/.env with your Supabase credentials"
    echo "  2. Run database migrations in Supabase dashboard"
    echo "  3. Create your first super admin user"
    echo "  4. Access your application at https://$DOMAIN"
    echo ""
    echo "Useful Commands:"
    echo "  - View logs: sudo -u $APP_USER pm2 logs $APP_NAME"
    echo "  - Restart app: sudo -u $APP_USER pm2 restart $APP_NAME"
    echo "  - Update app: sudo update-choo-system"
    echo "  - Check status: sudo -u $APP_USER pm2 status"
    echo ""
    print_info "For support, refer to the documentation in $APP_DIR/docs/"
}

# Main deployment function
main() {
    print_info "Starting deployment..."
    echo ""
    
    check_root
    get_configuration
    
    update_system
    install_nodejs
    install_pm2
    install_nginx
    install_certbot
    create_app_user
    create_directories
    copy_application
    configure_environment
    install_dependencies
    build_application
    create_server
    create_pm2_config
    start_application
    configure_nginx
    obtain_ssl
    setup_firewall
    create_update_script
    
    display_completion
}

# Run main function
main