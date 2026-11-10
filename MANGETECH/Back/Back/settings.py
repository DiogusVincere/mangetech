"""
Django settings do projeto Back (API do MangeTech).

Tudo que muda entre máquina de desenvolvimento e produção vem de variáveis de
ambiente. Veja o arquivo .env.example ao lado do manage.py.
"""

from pathlib import Path
import os

from django.core.management.utils import get_random_secret_key

# Build paths
BASE_DIR = Path(__file__).resolve().parent.parent

# Carrega um arquivo .env ao lado do manage.py, se existir (só conveniência de
# desenvolvimento; em produção defina as variáveis direto no ambiente).
try:
    from dotenv import load_dotenv

    load_dotenv(BASE_DIR / '.env')
except ImportError:  # python-dotenv é opcional
    pass


def _env_bool(nome, padrao=False):
    valor = os.environ.get(nome)
    if valor is None:
        return padrao
    return valor.strip().lower() in ('1', 'true', 't', 'yes', 'y', 'sim', 's', 'on')


def _env_lista(nome, padrao=''):
    """Lê uma lista separada por vírgula ("a,b,c") ignorando espaços e vazios."""
    return [item.strip() for item in os.environ.get(nome, padrao).split(',') if item.strip()]


# SECURITY WARNING: em produção a SECRET_KEY deve ser FIXA e vir do ambiente.
# Sem a variável, uma chave aleatória é gerada a cada inicialização: funciona
# para desenvolvimento, mas invalida sessões do admin e qualquer valor assinado
# a cada reinício do servidor.
SECRET_KEY = os.environ.get('SECRET_KEY') or get_random_secret_key()

# SECURITY WARNING: nunca rode com DEBUG=True em produção.
DEBUG = _env_bool('DEBUG', False)

ALLOWED_HOSTS = _env_lista('ALLOWED_HOSTS', 'localhost,127.0.0.1')

# Atrás de um proxy que termina TLS (Render, Azure, Nginx), é este cabeçalho
# que diz ao Django que a requisição original era HTTPS.
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')


# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third party apps
    'rest_framework',
    'rest_framework.authtoken',
    'django_filters',
    'corsheaders',

    # Local apps
    'chamados',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'corsheaders.middleware.CorsMiddleware',  # CORS deve vir antes do CommonMiddleware
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'Back.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'Back.wsgi.application'

# Database
# Sem DATABASE_URL: SQLite no disco (desenvolvimento e demonstração, que
# recomeça a cada deploy). Com DATABASE_URL (ex.: Postgres do Neon), os dados
# ficam fora do servidor e sobrevivem a deploys e reinícios.
DATABASE_URL = os.environ.get('DATABASE_URL', '').strip()
if DATABASE_URL:
    import dj_database_url

    DATABASES = {
        'default': dj_database_url.parse(DATABASE_URL, conn_max_age=60, conn_health_checks=True),
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'pt-br'
TIME_ZONE = 'America/Sao_Paulo'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images) — servidos pelo WhiteNoise depois de
# `python manage.py collectstatic`.
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Media files (uploads: fotos de comentários, do histórico e anexos)
MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Com as variáveis do Cloudflare R2, fotos e anexos vão para o bucket (privado:
# a API devolve links assinados que valem 1 hora). Sem elas, ficam em media/.
R2_BUCKET = os.environ.get('R2_BUCKET', '').strip()
USAR_R2 = bool(R2_BUCKET)
SERVE_MEDIA = _env_bool('SERVE_MEDIA', not USAR_R2)

# Uploads grandes vão para arquivo temporário; acima disso o Django recusa.
DATA_UPLOAD_MAX_MEMORY_SIZE = 25 * 1024 * 1024
FILE_UPLOAD_MAX_MEMORY_SIZE = 5 * 1024 * 1024

STORAGES = {
    'default': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    } if not USAR_R2 else {
        'BACKEND': 'storages.backends.s3.S3Storage',
        'OPTIONS': {
            'bucket_name': R2_BUCKET,
            'endpoint_url': os.environ.get('R2_ENDPOINT_URL')
            or f"https://{os.environ.get('R2_ACCOUNT_ID', '')}.r2.cloudflarestorage.com",
            'access_key': os.environ.get('R2_ACCESS_KEY_ID'),
            'secret_key': os.environ.get('R2_SECRET_ACCESS_KEY'),
            'region_name': 'auto',
            'signature_version': 's3v4',
            'default_acl': None,
            'querystring_auth': True,
            'querystring_expire': 3600,
            'file_overwrite': False,
        },
    },
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage',
    },
}

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ========== AUTHENTICATION CONFIGURATION ==========
AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
]

# ========== REST FRAMEWORK CONFIGURATION ==========
REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ],
    'DEFAULT_PARSER_CLASSES': [
        'rest_framework.parsers.JSONParser',
        'rest_framework.parsers.MultiPartParser',
        'rest_framework.parsers.FormParser',
    ],
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
    'EXCEPTION_HANDLER': 'chamados.exceptions.tratar_excecao',
    'DEFAULT_PAGINATION_CLASS': 'chamados.pagination.Paginacao',
    'PAGE_SIZE': 50,
    # Limite por IP nos endpoints públicos de login, cadastro e recuperação de senha.
    # Quantos proxies ficam na frente da API. 0 (padrão) usa REMOTE_ADDR e
    # ignora o X-Forwarded-For; no Render o render.yaml define 1, e o DRF passa a
    # usar o IP que o proxy acrescentou, não o que o cliente mandou.
    'NUM_PROXIES': int(os.environ.get('NUM_PROXIES', '0')),
    'DEFAULT_THROTTLE_RATES': {
        'auth': os.environ.get('AUTH_THROTTLE_RATE', '30/min'),
    },
    'DATETIME_FORMAT': '%Y-%m-%dT%H:%M:%S',
    'DATE_FORMAT': '%Y-%m-%d',
}

# ========== CORS / CSRF ==========
# Origens do front (Vue) e do app. Em produção, informe a URL publicada do front
# em CORS_ALLOWED_ORIGINS; com DEBUG=True qualquer origem é aceita.
CORS_ALLOWED_ORIGINS = _env_lista(
    'CORS_ALLOWED_ORIGINS',
    'http://localhost:5173,http://127.0.0.1:5173,'
    'http://localhost:3000,http://127.0.0.1:3000,'
    'http://localhost:8080,http://127.0.0.1:8080',
)
CORS_ALLOW_ALL_ORIGINS = DEBUG
CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

# Precisa do esquema (https://...). Por padrão, as mesmas origens do CORS.
CSRF_TRUSTED_ORIGINS = _env_lista('CSRF_TRUSTED_ORIGINS', ','.join(CORS_ALLOWED_ORIGINS))

# ========== EMAIL (recuperação de senha) ==========
# Com EMAIL_HOST_USER e EMAIL_HOST_PASSWORD definidos, envia por SMTP;
# sem eles, os e-mails saem no console (bom para desenvolvimento).
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')

if EMAIL_HOST_USER and EMAIL_HOST_PASSWORD:
    EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
    EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp.gmail.com')
    EMAIL_PORT = int(os.environ.get('EMAIL_PORT', '587'))
    EMAIL_USE_TLS = _env_bool('EMAIL_USE_TLS', True)
    DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', EMAIL_HOST_USER)
else:
    EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
    DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', 'noreply@mangetech.local')

# URL do front (para links nos e-mails)
FRONTEND_URL = os.environ.get('FRONTEND_URL', 'http://localhost:5173')

# ========== LOGGING ==========
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
