"""URLs do projeto Back (API do MangeTech)."""
from django.conf import settings
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path, re_path
from django.views.static import serve


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
        re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT}),
    ]
