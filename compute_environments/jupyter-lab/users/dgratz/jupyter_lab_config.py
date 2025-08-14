# Configuration file for lab.

c = get_config()  #noqa

#------------------------------------------------------------------------------
# Server Configuration
#------------------------------------------------------------------------------
# Set the root directory for notebooks and kernels
c.ServerApp.root_dir = '/fh/fast/_IRC/FHIL/grp/'
c.ServerApp.preferred_dir = '/fh/fast/_IRC/FHIL/grp/'
c.NotebookApp.notebook_dir = '/fh/fast/_IRC/FHIL/grp/'

# Allow root user (important for containerized environments)
c.ServerApp.allow_root = True

# Disable XSRF protection for easier access (use with caution in production)
# c.ServerApp.disable_check_xsrf = True

# Allow remote access (important for HPC environments)
c.ServerApp.allow_remote_access = True

# Set IP to bind to all interfaces
c.ServerApp.ip = '0.0.0.0'

# Set port (though your script overrides this)
# c.ServerApp.port = 8888

# Disable token authentication (for easier access)
c.ServerApp.token = ''

# Disable password requirement
c.ServerApp.password_required = False

# Allow unauthenticated access (use with caution in production)
c.ServerApp.allow_unauthenticated_access = True

# Enable file uploads
c.ServerApp.allow_credentials = True

# Set maximum file upload size (1GB)
c.ServerApp.max_body_size = 1073741824

# Enable terminals
c.ServerApp.terminals_enabled = True

# Set maximum buffer size for large files
c.ServerApp.max_buffer_size = 1073741824

#------------------------------------------------------------------------------
# Jupyter Lab Configuration
#------------------------------------------------------------------------------
# Set the default URL to redirect to
c.LabApp.default_url = '/lab'

# Enable collaborative features (if needed)
c.LabApp.collaborative = False

# Set user settings directory
c.LabApp.user_settings_dir = '/home/dgratz/.jupyter/lab/user-settings'

# Set workspaces directory
c.LabApp.workspaces_dir = '/home/dgratz/.jupyter/lab/workspaces'

# Whether a notebook should start a kernel automatically
c.LabApp.notebook_starts_kernel = True

# Whether to open in a browser after starting
c.LabApp.open_browser = False

#------------------------------------------------------------------------------
# Logging Configuration
#------------------------------------------------------------------------------
# Set log level (DEBUG, INFO, WARN, ERROR, CRITICAL)
c.ServerApp.log_level = 'INFO'

# Log format
c.ServerApp.log_format = '[%(name)s] %(levelname)s %(message)s'

#------------------------------------------------------------------------------
# Security and Access Control
#------------------------------------------------------------------------------
# Allow any origin to access your server (use with caution)
# c.ServerApp.allow_origin = '*'

# Trust X-Forwarded headers (important for proxy setups)
# c.ServerApp.trust_xheaders = True

#------------------------------------------------------------------------------
# Performance and Resource Management
#------------------------------------------------------------------------------
# Shut down server after N seconds with no kernels running
c.ServerApp.shutdown_no_activity_timeout = 36000  # 10 hrs

# WebSocket ping interval (keep connections alive)
c.ServerApp.websocket_ping_interval = 30

# WebSocket ping timeout
c.ServerApp.websocket_ping_timeout = 10

## The base URL for websockets,
#          if it differs from the HTTP server (hint: it almost certainly doesn't).
#  
#          Should be in the form of an HTTP origin: ws[s]://hostname[:port]
#  Default: ''
# c.ServerApp.websocket_url = ''
