"""URLs do projeto Back (API do MangeTech)."""
from django.conf import settings
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path, re_path
from django.views.static import serve

# Tipos que o navegador pode exibir direto; o resto (HTML, SVG, PDF...) vai
# como download em sandbox, para um anexo não rodar script na origem da API.
TIPOS_EXIBIVEIS = {'image/png', 'image/jpeg', 'image/gif', 'image/webp'}


def servir_upload(request, path):
    response = serve(request, path, document_root=settings.MEDIA_ROOT)
    response['X-Content-Type-Options'] = 'nosniff'
    tipo = (response.get('Content-Type') or '').split(';')[0].strip().lower()
    if tipo not in TIPOS_EXIBIVEIS:
        response['Content-Disposition'] = 'attachment'
        response['Content-Security-Policy'] = 'sandbox'
    return response


def health(request):
    return JsonResponse({'status': 'ok'})


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/health/', health, name='health'),
    path('api/', include('chamados.urls')),
]

# Uploads (fotos e anexos). Em produção sem storage externo (Render gratuito),
# o próprio Django serve a pasta media/; desligue com SERVE_MEDIA=False se
# houver um Nginx/CDN na frente.
if settings.SERVE_MEDIA:
    urlpatterns += [
        re_path(r'^media/(?P<path>.*)$', servir_upload),
    ]
